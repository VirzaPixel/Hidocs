import { useQuery } from '@tanstack/react-query';
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid } from 'recharts';
import { responseApi } from '../../lib/api';
import { Card, EmptyState, FullPageSpinner } from '../../shared/ui';

export default function AnalyticsTab({ formId }) {
  const { data, isLoading } = useQuery({
    queryKey: ['analytics', formId],
    queryFn: () => responseApi.analytics(formId),
  });

  if (isLoading) return <FullPageSpinner />;
  if (!data || data.total_responses === 0) {
    return <EmptyState title="Belum ada data analitik" description="Analitik muncul setelah ada respons yang masuk" />;
  }

  const breakdown = Object.values(data.question_breakdown || {});
  const chartData = breakdown.map((q, i) => ({
    name: `Soal ${i + 1}`,
    fullText: q.question_text,
    accuracy: Math.round((q.accuracy_rate || 0) * 100),
  }));

  return (
    <div className="flex flex-col gap-5">
      <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
        <StatCard label="Total Respons" value={data.total_responses} />
        <StatCard label="Rata-rata" value={data.average_score?.toFixed(1)} />
        <StatCard label="Tertinggi" value={data.highest_score} />
        <StatCard label="Terendah" value={data.lowest_score} />
      </div>

      {chartData.length > 0 && (
        <Card>
          <h3 className="mb-4 font-semibold text-text">Tingkat Akurasi per Soal</h3>
          <ResponsiveContainer width="100%" height={Math.max(240, chartData.length * 36)}>
            <BarChart data={chartData} layout="vertical" margin={{ left: 10, right: 20 }}>
              <CartesianGrid strokeDasharray="3 3" horizontal={false} stroke="var(--app-border)" />
              <XAxis type="number" domain={[0, 100]} unit="%" stroke="var(--app-text-secondary)" fontSize={12} />
              <YAxis type="category" dataKey="name" width={60} stroke="var(--app-text-secondary)" fontSize={12} />
              <Tooltip
                formatter={(value) => [`${value}%`, 'Akurasi']}
                labelFormatter={(label, payload) => payload?.[0]?.payload?.fullText || label}
                contentStyle={{ background: 'var(--app-surface)', border: '1px solid var(--app-border)', borderRadius: 8 }}
              />
              <Bar dataKey="accuracy" fill="var(--hp-pri)" radius={[0, 4, 4, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </Card>
      )}

      <Card>
        <h3 className="mb-3 font-semibold text-text">Rincian per Soal</h3>
        <div className="flex flex-col divide-y divide-border">
          {breakdown.map((q, i) => (
            <div key={i} className="flex items-center justify-between gap-3 py-2.5 text-sm">
              <span className="min-w-0 flex-1 truncate text-text">{q.question_text}</span>
              <span className="shrink-0 text-text-secondary">
                {q.correct_count}/{q.total_answered} benar &middot; {Math.round((q.accuracy_rate || 0) * 100)}%
              </span>
            </div>
          ))}
        </div>
      </Card>
    </div>
  );
}

function StatCard({ label, value }) {
  return (
    <Card className="text-center">
      <p className="text-2xl font-bold text-text">{value ?? '-'}</p>
      <p className="mt-1 text-xs text-text-secondary">{label}</p>
    </Card>
  );
}
