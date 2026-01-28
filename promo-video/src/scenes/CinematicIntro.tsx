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
  weights: ["300", "400", "500", "600", "700", "800"],
  subsets: ["latin"],
});

export const CinematicIntro: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Particles floating up
  const particles = Array.from({ length: 30 }, (_, i) => ({
    x: Math.sin(i * 0.7) * 400 + 540,
    startY: 2000 + (i % 5) * 200,
    speed: 3 + (i % 4) * 1.5,
    size: 2 + (i % 4) * 2,
    opacity: 0.1 + (i % 5) * 0.1,
    delay: (i % 8) * 5,
  }));

  // Logo reveal with dramatic timing
  const logoRevealProgress = interpolate(frame, [20, 60], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.bezier(0.16, 1, 0.3, 1),
  });

  const logoScale = interpolate(logoRevealProgress, [0, 1], [0.3, 1]);
  const logoOpacity = interpolate(logoRevealProgress, [0, 0.3], [0, 1], {
    extrapolateRight: "clamp",
  });
  const logoBlur = interpolate(logoRevealProgress, [0, 0.5], [20, 0], {
    extrapolateRight: "clamp",
  });

  // Glow pulse
  const glowPulse = interpolate(
    Math.sin((frame - 40) / 15),
    [-1, 1],
    [0.3, 0.8]
  );

  // Text reveal
  const textReveal = interpolate(frame, [55, 85], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.bezier(0.16, 1, 0.3, 1),
  });

  const textY = interpolate(textReveal, [0, 1], [40, 0]);
  const textOpacity = interpolate(textReveal, [0, 0.5], [0, 1], {
    extrapolateRight: "clamp",
  });

  // Tagline
  const taglineReveal = interpolate(frame, [75, 100], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.out(Easing.quad),
  });

  // Cinematic bars (letterbox effect)
  const barsHeight = interpolate(frame, [0, 30], [200, 80], {
    extrapolateRight: "clamp",
    easing: Easing.out(Easing.quad),
  });

  // Fade out at end
  const fadeOut = interpolate(frame, [100, 120], [1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  return (
    <AbsoluteFill
      style={{
        background: "linear-gradient(180deg, #050810 0%, #0B132B 50%, #0a0f1f 100%)",
        fontFamily,
        opacity: fadeOut,
      }}
    >
      {/* Animated particles */}
      {particles.map((p, i) => {
        const y = p.startY - (frame - p.delay) * p.speed;
        if (y < -50 || frame < p.delay) return null;

        return (
          <div
            key={i}
            style={{
              position: "absolute",
              left: p.x + Math.sin((frame + i * 10) / 20) * 30,
              top: y,
              width: p.size,
              height: p.size,
              borderRadius: "50%",
              background: "#FFFFFF",
              opacity: p.opacity * interpolate(y, [100, 400, 1600, 1900], [0, 1, 1, 0], {
                extrapolateLeft: "clamp",
                extrapolateRight: "clamp",
              }),
              boxShadow: `0 0 ${p.size * 3}px rgba(255,255,255,0.5)`,
            }}
          />
        );
      })}

      {/* Radial glow behind logo */}
      <div
        style={{
          position: "absolute",
          top: "50%",
          left: "50%",
          transform: "translate(-50%, -50%)",
          width: 600,
          height: 600,
          borderRadius: "50%",
          background: `radial-gradient(circle, rgba(255,255,255,${glowPulse * 0.15}) 0%, transparent 70%)`,
          opacity: logoRevealProgress,
        }}
      />

      {/* Main logo */}
      <div
        style={{
          position: "absolute",
          top: "42%",
          left: "50%",
          transform: `translate(-50%, -50%) scale(${logoScale})`,
          opacity: logoOpacity,
          filter: `blur(${logoBlur}px)`,
        }}
      >
        <Img
          src={staticFile("app_icon.png")}
          style={{
            width: 200,
            height: 200,
            borderRadius: 45,
            boxShadow: `
              0 0 100px rgba(255,255,255,${glowPulse * 0.4}),
              0 30px 60px rgba(0,0,0,0.5)
            `,
          }}
        />
      </div>

      {/* Brand name */}
      <div
        style={{
          position: "absolute",
          top: "58%",
          left: "50%",
          transform: `translate(-50%, 0) translateY(${textY}px)`,
          opacity: textOpacity,
          textAlign: "center",
        }}
      >
        <div
          style={{
            fontSize: 90,
            fontWeight: 700,
            color: "#FFFFFF",
            letterSpacing: -3,
            textShadow: "0 0 60px rgba(255,255,255,0.3)",
          }}
        >
          Ryze
        </div>
      </div>

      {/* Tagline */}
      <div
        style={{
          position: "absolute",
          top: "70%",
          left: "50%",
          transform: "translate(-50%, 0)",
          opacity: taglineReveal,
          textAlign: "center",
        }}
      >
        <div
          style={{
            fontSize: 32,
            fontWeight: 400,
            color: "rgba(255,255,255,0.7)",
            letterSpacing: 8,
            textTransform: "uppercase",
          }}
        >
          Planificateur IA
        </div>
      </div>

      {/* Cinematic letterbox bars */}
      <div
        style={{
          position: "absolute",
          top: 0,
          left: 0,
          right: 0,
          height: barsHeight,
          background: "#000000",
        }}
      />
      <div
        style={{
          position: "absolute",
          bottom: 0,
          left: 0,
          right: 0,
          height: barsHeight,
          background: "#000000",
        }}
      />

      {/* Subtle vignette */}
      <div
        style={{
          position: "absolute",
          inset: 0,
          background: "radial-gradient(ellipse at center, transparent 40%, rgba(0,0,0,0.6) 100%)",
          pointerEvents: "none",
        }}
      />
    </AbsoluteFill>
  );
};
