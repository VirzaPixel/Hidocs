package websocket

import (
	"encoding/json"
	"log"
	"net/http"
	"sync"
	"time"

	"github.com/google/uuid"
	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin: func(r *http.Request) bool {
		return true // Allow CORS for all web/mobile clients
	},
}

type Client struct {
	Hub      *Hub
	Conn     *websocket.Conn
	FormID   uuid.UUID
	SendChan chan []byte
}

type BroadcastMessage struct {
	FormID  uuid.UUID `json:"form_id"`
	Type    string    `json:"type"` // "STUDENT_JOIN", "STUDENT_UPDATE", "STUDENT_SUBMIT", "TELEMETRY"
	Payload any       `json:"payload"`
}

type Hub struct {
	clients    map[uuid.UUID]map[*Client]bool
	broadcast  chan BroadcastMessage
	register   chan *Client
	unregister chan *Client
	mu         sync.RWMutex
}

var GlobalHub = NewHub()

func NewHub() *Hub {
	h := &Hub{
		clients:    make(map[uuid.UUID]map[*Client]bool),
		broadcast:  make(chan BroadcastMessage, 100),
		register:   make(chan *Client),
		unregister: make(chan *Client),
	}
	go h.run()
	return h
}

func (h *Hub) run() {
	for {
		select {
		case client := <-h.register:
			h.mu.Lock()
			if h.clients[client.FormID] == nil {
				h.clients[client.FormID] = make(map[*Client]bool)
			}
			h.clients[client.FormID][client] = true
			h.mu.Unlock()

		case client := <-h.unregister:
			h.mu.Lock()
			if clients, ok := h.clients[client.FormID]; ok {
				if _, exists := clients[client]; exists {
					delete(clients, client)
					close(client.SendChan)
					if len(clients) == 0 {
						delete(h.clients, client.FormID)
					}
				}
			}
			h.mu.Unlock()

		case msg := <-h.broadcast:
			h.mu.RLock()
			clients := h.clients[msg.FormID]
			jsonBytes, err := json.Marshal(msg)
			if err == nil && len(clients) > 0 {
				for client := range clients {
					select {
					case client.SendChan <- jsonBytes:
					default:
						close(client.SendChan)
						delete(clients, client)
					}
				}
			}
			h.mu.RUnlock()
		}
	}
}

func (h *Hub) BroadcastToForm(formID uuid.UUID, eventType string, payload any) {
	h.broadcast <- BroadcastMessage{
		FormID:  formID,
		Type:    eventType,
		Payload: payload,
	}
}

func (c *Client) ReadPump() {
	defer func() {
		c.Hub.unregister <- c
		c.Conn.Close()
	}()

	c.Conn.SetReadLimit(512)
	_ = c.Conn.SetReadDeadline(time.Now().Add(60 * time.Second))
	c.Conn.SetPongHandler(func(string) error {
		_ = c.Conn.SetReadDeadline(time.Now().Add(60 * time.Second))
		return nil
	})

	for {
		_, _, err := c.Conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				log.Printf("ws error: %v", err)
			}
			break
		}
	}
}

func (c *Client) WritePump() {
	ticker := time.NewTicker(25 * time.Second)
	defer func() {
		ticker.Stop()
		c.Conn.Close()
	}()

	for {
		select {
		case message, ok := <-c.SendChan:
			_ = c.Conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
			if !ok {
				_ = c.Conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}

			w, err := c.Conn.NextWriter(websocket.TextMessage)
			if err != nil {
				return
			}
			_, _ = w.Write(message)

			n := len(c.SendChan)
			for i := 0; i < n; i++ {
				_, _ = w.Write([]byte{'\n'})
				_, _ = w.Write(<-c.SendChan)
			}

			if err := w.Close(); err != nil {
				return
			}

		case <-ticker.C:
			_ = c.Conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
			if err := c.Conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}

func ServeWS(hub *Hub, w http.ResponseWriter, r *http.Request, formID uuid.UUID) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("failed to upgrade websocket: %v", err)
		return
	}

	client := &Client{
		Hub:      hub,
		Conn:     conn,
		FormID:   formID,
		SendChan: make(chan []byte, 256),
	}
	client.Hub.register <- client

	go client.WritePump()
	go client.ReadPump()
}
