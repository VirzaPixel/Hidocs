package handler

import (
	infraWS "backend/internal/infrastructure/websocket"
	"backend/pkg/response"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type WSHandler struct {
	hub *infraWS.Hub
}

func NewWSHandler(hub *infraWS.Hub) *WSHandler {
	if hub == nil {
		hub = infraWS.GlobalHub
	}
	return &WSHandler{hub: hub}
}

func (h *WSHandler) HandleLiveMonitoring(c *gin.Context) {
	formID, err := uuid.Parse(c.Param("form_id"))
	if err != nil {
		response.BadRequest(c, "Invalid form_id UUID", err)
		return
	}

	infraWS.ServeWS(h.hub, c.Writer, c.Request, formID)
}
