package domain

// Pagination adalah parameter + hasil paging generik yang dipakai lintas endpoint
// list (mis. daftar respons ujian). Dipakai lewat pkg/pagination.FromQuery(c, ...)
// di layer handler, lalu diteruskan ke service -> repository.
type Pagination struct {
	Limit  int   `json:"limit"`
	Offset int   `json:"offset"`
	Total  int64 `json:"total,omitempty"` // diisi repository setelah query COUNT, bukan input
}

// Normalize memastikan Limit selalu masuk akal: pakai default kalau tidak diisi/negatif,
// dan tidak pernah melebihi maxLimit (supaya tidak ada yang iseng minta limit=999999
// dan bikin query berat di database).
func (p Pagination) Normalize(defaultLimit, maxLimit int) Pagination {
	if p.Limit <= 0 {
		p.Limit = defaultLimit
	}
	if maxLimit > 0 && p.Limit > maxLimit {
		p.Limit = maxLimit
	}
	if p.Offset < 0 {
		p.Offset = 0
	}
	return p
}
