const { useState, useEffect } = React;

function Button({ variant = 'primary', size = 'md', children, onClick, disabled, style }) {
  const sizes = {
    sm: { padding: '6px 12px', fontSize: 13 },
    md: { padding: '10px 18px', fontSize: 15 },
    lg: { padding: '14px 24px', fontSize: 17 },
  };
  const variants = {
    primary: { background: '#122559', color: '#fff', border: '1px solid #122559' },
    cta:     { background: '#d4245c', color: '#fff', border: '1px solid #d4245c' },
    outline: { background: '#fff', color: '#122559', border: '1px solid #dde1ec' },
    ghost:   { background: 'transparent', color: '#4934ad', border: '1px solid transparent' },
  };
  return (
    <button onClick={disabled ? undefined : onClick}
      style={{
        fontFamily: 'Figtree, sans-serif', fontWeight: 600, borderRadius: 10,
        cursor: disabled ? 'not-allowed' : 'pointer', opacity: disabled ? 0.4 : 1,
        transition: 'all 180ms cubic-bezier(0.2,0.7,0.2,1)',
        ...variants[variant], ...sizes[size], ...style,
      }}>{children}</button>
  );
}

function Field({ label, value, onChange, type = 'text', placeholder, hint, error, autoFocus }) {
  return (
    <label style={{ display: 'block' }}>
      <div style={{ fontSize: 12, fontWeight: 600, color: '#3a4468', marginBottom: 6 }}>{label}</div>
      <input type={type} value={value} onChange={e => onChange && onChange(e.target.value)}
        placeholder={placeholder} autoFocus={autoFocus}
        style={{
          width: '100%', boxSizing: 'border-box', fontFamily: 'inherit', fontSize: 15,
          padding: '10px 12px', borderRadius: 8,
          border: `1px solid ${error ? '#d4245c' : '#dde1ec'}`, background: '#fff',
          color: '#122559', outline: 'none',
        }}
        onFocus={e => e.target.style.boxShadow = '0 0 0 3px rgba(73,52,173,.25)'}
        onBlur={e => e.target.style.boxShadow = 'none'}
      />
      {hint && <div style={{ fontSize: 12, color: error ? '#d4245c' : '#6b7597', marginTop: 4 }}>{hint}</div>}
    </label>
  );
}

function Chip({ tone = 'neutral', children }) {
  const tones = {
    success: { bg: '#e4f4ec', fg: '#1f8a5a', dot: '#1f8a5a' },
    warning: { bg: '#fdf0dc', fg: '#b25b00', dot: '#b25b00' },
    danger:  { bg: '#fbdce6', fg: '#d4245c', dot: '#d4245c' },
    info:    { bg: '#eeeafa', fg: '#4934ad', dot: '#4934ad' },
    neutral: { bg: '#eef0f7', fg: '#3a4468', dot: '#6b7597' },
  }[tone];
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 6,
      padding: '4px 10px', borderRadius: 999,
      background: tones.bg, color: tones.fg,
      fontSize: 12, fontWeight: 600,
    }}>
      <span style={{ width: 6, height: 6, borderRadius: '50%', background: tones.dot }} />
      {children}
    </span>
  );
}

function ScaleReadout({ value, unit = 'kg' }) {
  return (
    <div style={{
      fontFamily: 'Figtree, sans-serif', fontWeight: 600,
      fontSize: 72, lineHeight: 1, letterSpacing: '-0.02em',
      color: '#122559', fontVariantNumeric: 'tabular-nums',
    }}>
      {value.toFixed(2)}
      <span style={{ fontSize: 28, fontWeight: 400, color: '#6b7597', marginLeft: 8 }}>{unit}</span>
    </div>
  );
}

function ToleranceBar({ current, target, band }) {
  const min = target - band, max = target + band;
  const range = (max - min) * 1.6; // visual padding
  const visMin = target - range / 2;
  const pct = v => Math.max(0, Math.min(100, ((v - visMin) / range) * 100));
  const inTol = current >= min && current <= max;
  return (
    <div style={{ position: 'relative', height: 48 }}>
      <div style={{
        position: 'absolute', left: 0, right: 0, top: 20, height: 8,
        background: '#eef0f7', borderRadius: 4,
      }} />
      {/* tolerance band */}
      <div style={{
        position: 'absolute', top: 20, height: 8,
        left: `${pct(min)}%`, width: `${pct(max) - pct(min)}%`,
        background: '#e4f4ec', borderRadius: 4,
      }} />
      {/* target line */}
      <div style={{
        position: 'absolute', top: 12, bottom: 12,
        left: `${pct(target)}%`, width: 2, background: '#4934ad',
      }} />
      {/* current indicator */}
      <div style={{
        position: 'absolute', top: 8, height: 32, width: 4,
        left: `calc(${pct(current)}% - 2px)`,
        background: inTol ? '#1f8a5a' : '#d4245c',
        borderRadius: 2, boxShadow: `0 0 0 3px ${inTol ? 'rgba(31,138,90,.2)' : 'rgba(212,36,92,.2)'}`,
        transition: 'left 180ms cubic-bezier(0.2,0.7,0.2,1)',
      }} />
      <div style={{ position: 'absolute', top: 32, left: `${pct(min)}%`, fontSize: 11, color: '#6b7597', fontVariantNumeric: 'tabular-nums' }}>{min.toFixed(2)}</div>
      <div style={{ position: 'absolute', top: 32, left: `${pct(target)}%`, transform: 'translateX(-50%)', fontSize: 11, color: '#4934ad', fontWeight: 600, fontVariantNumeric: 'tabular-nums' }}>{target.toFixed(2)}</div>
      <div style={{ position: 'absolute', top: 32, left: `${pct(max)}%`, transform: 'translateX(-100%)', fontSize: 11, color: '#6b7597', fontVariantNumeric: 'tabular-nums' }}>{max.toFixed(2)}</div>
    </div>
  );
}

Object.assign(window, { Button, Field, Chip, ScaleReadout, ToleranceBar });
