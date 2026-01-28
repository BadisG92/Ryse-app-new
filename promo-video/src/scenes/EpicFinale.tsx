import {
  AbsoluteFill,
  Img,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
  interpolate,
  spring,
  Easing,
} from "remotion";
import { loadFont } from "@remotion/google-fonts/Inter";

const { fontFamily } = loadFont("normal", {
  weights: ["400", "500", "600", "700", "800"],
  subsets: ["latin"],
});

export const EpicFinale: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Epic entrance
  const entranceProgress = interpolate(frame, [0, 25], [0, 1], {
    extrapolateRight: "clamp",
    easing: Easing.bezier(0.16, 1, 0.3, 1),
  });

  const contentScale = interpolate(entranceProgress, [0, 1], [0.85, 1]);
  const contentOpacity = interpolate(entranceProgress, [0, 0.3], [0, 1], {
    extrapolateRight: "clamp",
  });

  // Logo pulse
  const logoPulse = interpolate(
    Math.sin((frame - 20) / 12),
    [-1, 1],
    [1, 1.05]
  );

  // Button entrance
  const buttonSpring = spring({
    frame: frame - 25,
    fps,
    config: { damping: 12, stiffness: 100 },
  });

  const buttonScale = interpolate(buttonSpring, [0, 1], [0.8, 1], {
    extrapolateLeft: "clamp",
  });
  const buttonOpacity = interpolate(buttonSpring, [0, 1], [0, 1], {
    extrapolateLeft: "clamp",
  });

  // Particles
  const particles = Array.from({ length: 20 }, (_, i) => ({
    x: 540 + Math.cos(i * 0.8) * (200 + (i % 4) * 80),
    y: 800 + Math.sin(i * 0.8) * (150 + (i % 3) * 60),
    size: 4 + (i % 4) * 3,
    speed: 0.5 + (i % 3) * 0.3,
    delay: i * 2,
  }));

  return (
    <AbsoluteFill
      style={{
        background: "#0B132B",
        fontFamily,
      }}
    >
      {/* Animated gradient background */}
      <div
        style={{
          position: "absolute",
          inset: 0,
          background: `
            radial-gradient(ellipse at 50% 40%, rgba(59, 130, 246, 0.15) 0%, transparent 50%),
            radial-gradient(ellipse at 30% 70%, rgba(139, 92, 246, 0.1) 0%, transparent 40%),
            radial-gradient(ellipse at 70% 80%, rgba(16, 185, 129, 0.1) 0%, transparent 40%)
          `,
          opacity: entranceProgress,
        }}
      />

      {/* Floating particles */}
      {particles.map((p, i) => {
        const particleY = p.y - (frame - p.delay) * p.speed;
        const particleOpacity = interpolate(
          frame - p.delay,
          [0, 20, 60, 80],
          [0, 0.6, 0.6, 0],
          { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
        );

        if (frame < p.delay) return null;

        return (
          <div
            key={i}
            style={{
              position: "absolute",
              left: p.x + Math.sin((frame + i * 10) / 25) * 20,
              top: particleY,
              width: p.size,
              height: p.size,
              borderRadius: "50%",
              background: "#FFFFFF",
              opacity: particleOpacity,
              boxShadow: "0 0 10px rgba(255,255,255,0.5)",
            }}
          />
        );
      })}

      {/* Main content */}
      <div
        style={{
          position: "absolute",
          top: "50%",
          left: "50%",
          transform: `translate(-50%, -50%) scale(${contentScale})`,
          opacity: contentOpacity,
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
        }}
      >
        {/* App icon with glow */}
        <div
          style={{
            position: "relative",
            marginBottom: 40,
            transform: `scale(${frame > 20 ? logoPulse : 1})`,
          }}
        >
          {/* Glow */}
          <div
            style={{
              position: "absolute",
              inset: -30,
              background: "radial-gradient(circle, rgba(255,255,255,0.2) 0%, transparent 70%)",
              borderRadius: "50%",
            }}
          />
          <Img
            src={staticFile("app_icon.png")}
            style={{
              width: 140,
              height: 140,
              borderRadius: 32,
              boxShadow: "0 20px 60px rgba(0,0,0,0.4), 0 0 80px rgba(255,255,255,0.1)",
            }}
          />
        </div>

        {/* Headline */}
        <div
          style={{
            fontSize: 52,
            fontWeight: 700,
            color: "#FFFFFF",
            textAlign: "center",
            lineHeight: 1.1,
            marginBottom: 16,
          }}
        >
          Prêt à
          <br />
          <span
            style={{
              background: "linear-gradient(135deg, #10B981 0%, #3B82F6 50%, #8B5CF6 100%)",
              backgroundClip: "text",
              WebkitBackgroundClip: "text",
              WebkitTextFillColor: "transparent",
            }}
          >
            transformer
          </span>
          <br />
          ta semaine ?
        </div>

        {/* Subheadline */}
        <div
          style={{
            fontSize: 22,
            color: "rgba(255,255,255,0.7)",
            marginBottom: 50,
          }}
        >
          7 jours d'essai gratuit
        </div>

        {/* CTA Button */}
        <div
          style={{
            opacity: buttonOpacity,
            transform: `scale(${buttonScale})`,
          }}
        >
          <div
            style={{
              background: "#FFFFFF",
              borderRadius: 16,
              padding: "20px 50px",
              display: "flex",
              alignItems: "center",
              gap: 12,
              boxShadow: "0 20px 60px rgba(255,255,255,0.15)",
            }}
          >
            <span
              style={{
                fontSize: 22,
                fontWeight: 700,
                color: "#0B132B",
              }}
            >
              Télécharger Ryze
            </span>
            <span style={{ fontSize: 20 }}>→</span>
          </div>
        </div>
      </div>

      {/* App Store indicator */}
      <div
        style={{
          position: "absolute",
          bottom: 140,
          left: "50%",
          transform: "translateX(-50%)",
          opacity: interpolate(frame, [40, 55], [0, 1], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          }),
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          gap: 8,
        }}
      >
        <div
          style={{
            fontSize: 14,
            color: "rgba(255,255,255,0.5)",
            letterSpacing: 1,
          }}
        >
          DISPONIBLE SUR
        </div>
        <div
          style={{
            fontSize: 18,
            fontWeight: 600,
            color: "#FFFFFF",
          }}
        >
          App Store
        </div>
      </div>

      {/* Brand */}
      <div
        style={{
          position: "absolute",
          bottom: 60,
          left: "50%",
          transform: "translateX(-50%)",
          opacity: interpolate(frame, [50, 65], [0, 0.5], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          }),
        }}
      >
        <span
          style={{
            fontSize: 24,
            fontWeight: 700,
            color: "#FFFFFF",
            letterSpacing: 6,
          }}
        >
          RYZE
        </span>
      </div>

      {/* Vignette */}
      <div
        style={{
          position: "absolute",
          inset: 0,
          background: "radial-gradient(ellipse at center, transparent 50%, rgba(0,0,0,0.4) 100%)",
          pointerEvents: "none",
        }}
      />
    </AbsoluteFill>
  );
};
