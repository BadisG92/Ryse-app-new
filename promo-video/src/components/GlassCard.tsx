import React from "react";
import { useCurrentFrame, spring, useVideoConfig, interpolate } from "remotion";

interface GlassCardProps {
  children: React.ReactNode;
  delay?: number;
  style?: React.CSSProperties;
  blur?: number;
  opacity?: number;
  borderColor?: string;
}

export const GlassCard: React.FC<GlassCardProps> = ({
  children,
  delay = 0,
  style = {},
  blur = 20,
  opacity = 0.9,
  borderColor = "rgba(255,255,255,0.3)",
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const cardSpring = spring({
    frame: frame - delay,
    fps,
    config: {
      damping: 14,
      stiffness: 150,
      mass: 0.8,
    },
  });

  const scale = interpolate(cardSpring, [0, 1], [0.9, 1]);
  const cardOpacity = interpolate(cardSpring, [0, 0.5], [0, 1], {
    extrapolateRight: "clamp",
  });
  const y = interpolate(cardSpring, [0, 1], [20, 0]);

  return (
    <div
      style={{
        background: `rgba(255, 255, 255, ${opacity})`,
        backdropFilter: `blur(${blur}px)`,
        WebkitBackdropFilter: `blur(${blur}px)`,
        borderRadius: 16,
        border: `1px solid ${borderColor}`,
        padding: "16px 24px",
        boxShadow: `
          0 8px 32px rgba(11, 19, 43, 0.1),
          0 2px 8px rgba(11, 19, 43, 0.05)
        `,
        opacity: cardOpacity,
        transform: `translateY(${y}px) scale(${scale})`,
        ...style,
      }}
    >
      {children}
    </div>
  );
};

// Badge variant - smaller, more prominent
interface BadgeProps {
  text: string;
  delay?: number;
  color?: string;
  backgroundColor?: string;
  style?: React.CSSProperties;
}

export const Badge: React.FC<BadgeProps> = ({
  text,
  delay = 0,
  color = "#FFFFFF",
  backgroundColor = "#0B132B",
  style = {},
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const badgeSpring = spring({
    frame: frame - delay,
    fps,
    config: {
      damping: 12,
      stiffness: 200,
      mass: 0.5,
    },
  });

  const scale = interpolate(badgeSpring, [0, 1], [0.5, 1]);
  const opacity = interpolate(badgeSpring, [0, 0.3], [0, 1], {
    extrapolateRight: "clamp",
  });

  return (
    <div
      style={{
        display: "inline-flex",
        alignItems: "center",
        gap: 8,
        background: backgroundColor,
        color: color,
        borderRadius: 12,
        padding: "10px 20px",
        fontSize: 16,
        fontWeight: 600,
        opacity,
        transform: `scale(${scale})`,
        boxShadow: `0 8px 24px ${backgroundColor}40`,
        ...style,
      }}
    >
      {text}
    </div>
  );
};

// Gradient Badge - using Ryze gradient
export const GradientBadge: React.FC<BadgeProps> = ({
  text,
  delay = 0,
  style = {},
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const badgeSpring = spring({
    frame: frame - delay,
    fps,
    config: {
      damping: 12,
      stiffness: 200,
      mass: 0.5,
    },
  });

  const scale = interpolate(badgeSpring, [0, 1], [0.5, 1]);
  const opacity = interpolate(badgeSpring, [0, 0.3], [0, 1], {
    extrapolateRight: "clamp",
  });

  return (
    <div
      style={{
        display: "inline-flex",
        alignItems: "center",
        gap: 8,
        background: "linear-gradient(135deg, #0B132B 0%, #1C2951 100%)",
        color: "#FFFFFF",
        borderRadius: 14,
        padding: "12px 24px",
        fontSize: 18,
        fontWeight: 700,
        opacity,
        transform: `scale(${scale})`,
        boxShadow: `
          0 12px 32px rgba(11, 19, 43, 0.3),
          0 4px 12px rgba(11, 19, 43, 0.2)
        `,
        ...style,
      }}
    >
      {text}
    </div>
  );
};

// Success Badge with checkmark
export const SuccessBadge: React.FC<BadgeProps> = ({
  text,
  delay = 0,
  style = {},
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const badgeSpring = spring({
    frame: frame - delay,
    fps,
    config: {
      damping: 12,
      stiffness: 200,
      mass: 0.5,
    },
  });

  const scale = interpolate(badgeSpring, [0, 1], [0.5, 1]);
  const opacity = interpolate(badgeSpring, [0, 0.3], [0, 1], {
    extrapolateRight: "clamp",
  });

  return (
    <div
      style={{
        display: "inline-flex",
        alignItems: "center",
        gap: 10,
        background: "#10B981",
        color: "#FFFFFF",
        borderRadius: 14,
        padding: "14px 28px",
        fontSize: 20,
        fontWeight: 700,
        opacity,
        transform: `scale(${scale})`,
        boxShadow: `
          0 12px 32px rgba(16, 185, 129, 0.35),
          0 4px 12px rgba(16, 185, 129, 0.2)
        `,
        ...style,
      }}
    >
      <svg
        width="22"
        height="22"
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth="3"
        strokeLinecap="round"
        strokeLinejoin="round"
      >
        <polyline points="20 6 9 17 4 12" />
      </svg>
      {text}
    </div>
  );
};
