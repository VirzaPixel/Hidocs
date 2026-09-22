package pagination

import (
	"backend/internal/domain"
	"strconv"

	"github.com/gin-gonic/gin"
)

// FromQuery membaca ?limit=&offset= atau ?page=&page_size= secara general.
// Default + max diisi per-endpoint oleh pemanggil.
func FromQuery(c *gin.Context, defaultLimit, maxLimit int) domain.Pagination {
	limit := defaultLimit
	offset := 0
	if v := c.Query("limit"); v != "" {
		if n, err := strconv.Atoi(v); err == nil {
			limit = n
		}
	} else if v := c.Query("page_size"); v != "" {
		if n, err := strconv.Atoi(v); err == nil {
			limit = n
		}
	}
	if v := c.Query("offset"); v != "" {
		if n, err := strconv.Atoi(v); err == nil {
			offset = n
		}
	} else if v := c.Query("page"); v != "" {
		if n, err := strconv.Atoi(v); err == nil && n > 1 {
			offset = (n - 1) * limit
		}
	}
	return domain.Pagination{Limit: limit, Offset: offset}.Normalize(defaultLimit, maxLimit)
}
