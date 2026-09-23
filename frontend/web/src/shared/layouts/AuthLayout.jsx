import hidocsLogo from '../../assets/images/logo.png';

export default function AuthLayout({ title, subtitle, children }) {
  return (
    <div className="flex min-h-screen w-full items-center justify-center bg-bg-secondary px-4 py-10">
      <div className="w-full max-w-md">
        <div className="mb-6 flex flex-col items-center gap-2 text-center">
          <img src={hidocsLogo} alt="HiDocs Logo" className="h-12 w-12 rounded-xl object-contain" />
          <h1 className="text-xl font-bold text-text">HiDocs</h1>
        </div>
        <div className="rounded-xl border border-border bg-surface p-6 shadow-sm sm:p-8">
          {title && <h2 className="text-lg font-semibold text-text">{title}</h2>}
          {subtitle && <p className="mt-1 text-sm text-text-secondary">{subtitle}</p>}
          <div className="mt-6">{children}</div>
        </div>
      </div>
    </div>
  );
}
