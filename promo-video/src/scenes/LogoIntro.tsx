import {
  AbsoluteFill,
  Img,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
  spring,
  interpolate,
} from "remotion";
import { loadFont } from "@remotion/google-fonts/Inter";
import { AnimatedText } from "../components/AnimatedText";

const { fontFamily } = loadFont("normal", {
  weights: ["400", "500", "600", "700", "800", "900"],
  subsets: ["latin"],
});

export const LogoIntro: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Fade out at the end
  const fadeOut = interpolate(frame, [100, 120], [1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  // Logo entrance with spring bounce
  const logoSpring = spring({
    frame,
    fps,
    config: {
      damping: 12,
      stiffness: 150,
      mass: 0.8,
    },
  });

  const logoScale = interpolate(logoSpring, [0, 1], [0.3, 1]);
  const logoOpacity = interpolate(logoSpring, [0, 0.3], [0, 1], {
    extrapolateRight: "clamp",
  });

  // Subtle glow pulse
  const glowPulse = interpolate(
    Math.sin(frame / 20),
    [-1, 1],
    [0.3, 0.6]
  );

  // Blue particles
  const particles = Array.from({ length: 20 }, (_, i) => ({
    x: 540 + Math.cos(i * 0.32) * (200 + (i % 4) * 80),
    y: 960 + Math.sin(i * 0.32) * (150 + (i % 5) * 50),
    size: 4 + (i % 4) * 3,
    speed: 0.4 + (i % 3) * 0.25,
    delay: i * 2,
  }));

  // Animated rings
  const rings = Array.from({ length: 3 }, (_, i) => ({
    delay: 15 + i * 20,
    size: 200 + i * 100,
  }));

  // Floating shapes
  const shapes = Array.from({ length: 6 }, (_, i) => ({
    x: 100 + (i % 3) * 380,
    y: 300 + Math.floor(i / 3) * 800,
    size: 20 + (i % 3) * 15,
    rotation: i * 60,
    delay: 10 + i * 8,
  }));

  return (
    <AbsoluteFill
      style={{
        background: "linear-gradient(180deg, #FFFFFF 0%, #F8FAFC 100%)",
        fontFamily,
        opacity: fadeOut,
      }}
    >
      {/* Subtle radial gradient for depth */}
      <div
        style={{
          position: "absolute",
          inset: 0,
          background: "radial-gradient(ellipse at 50% 45%, rgba(11,19,43,0.03) 0%, transparent 60%)",
        }}
      />

      {/* Animated expanding rings */}
      {rings.map((ring, i) => {
        const ringProgress = interpolate(
          frame - ring.delay,
          [0, 60],
          [0, 1],
          { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
        );
        const ringScale = interpolate(ringProgress, [0, 1], [0.5, 2]);
        const ringOpacity = interpolate(ringProgress, [0, 0.3, 1], [0, 0.15, 0]);

        if (frame < ring.delay) return null;

        return (
          <div
            key={`ring-${i}`}
            style={{
              position: "absolute",
              top: "45%",
              left: "50%",
              transform: `translate(-50%, -50%) scale(${ringScale})`,
              width: ring.size,
              height: ring.size,
              borderRadius: "50%",
              border: "2px solid #0B132B",
              opacity: ringOpacity,
            }}
          />
        );
      })}

      {/* Floating geometric shapes */}
      {shapes.map((shape, i) => {
        const shapeProgress = frame - shape.delay;
        const floatY = Math.sin(shapeProgress / 25) * 20;
        const rotation = shape.rotation + shapeProgress * 0.5;
        const shapeOpacity = interpolate(
          shapeProgress,
          [0, 20, 80, 100],
          [0, 0.2, 0.2, 0],
          { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
        );

        if (frame < shape.delay) return null;

        return (
          <div
            key={`shape-${i}`}
            style={{
              position: "absolute",
              left: shape.x,
              top: shape.y + floatY,
              width: shape.size,
              height: shape.size,
              background: i % 2 === 0 ? "transparent" : "#0B132B",
              border: i % 2 === 0 ? "2px solid #0B132B" : "none",
              borderRadius: i % 3 === 0 ? "50%" : "4px",
              opacity: shapeOpacity,
              transform: `rotate(${rotation}deg)`,
            }}
          />
        );
      })}

      {/* Floating blue particles */}
      {particles.map((p, i) => {
        const particleY = p.y - (frame - p.delay) * p.speed;
        const particleOpacity = interpolate(
          frame - p.delay,
          [0, 15, 80, 100],
          [0, 0.5, 0.5, 0],
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
              background: i % 3 === 0 ? "#1C2951" : "#0B132B",
              opacity: particleOpacity,
              boxShadow: i % 2 === 0 ? "0 0 10px rgba(11,19,43,0.3)" : "none",
            }}
          />
        );
      })}

      {/* Panda in bottom left corner */}
      <div
        style={{
          position: "absolute",
          bottom: -40,
          left: -40,
          opacity: interpolate(frame, [30, 50], [0, 1], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          }),
          transform: `translateY(${interpolate(frame, [30, 50], [50, 0], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          })}px) rotate(-5deg)`,
        }}
      >
        <Img
          src={staticFile("coach_ryze_welcome_arms.png")}
          style={{
            width: 500,
            height: 500,
            objectFit: "contain",
          }}
        />
      </div>

      {/* Panda in bottom right corner */}
      <div
        style={{
          position: "absolute",
          bottom: -20,
          right: -40,
          opacity: interpolate(frame, [40, 60], [0, 1], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          }),
          transform: `translateY(${interpolate(frame, [40, 60], [50, 0], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          })}px) rotate(5deg)`,
        }}
      >
        <Img
          src={staticFile("coach_ryze_chef_avatar.png")}
          style={{
            width: 450,
            height: 450,
            objectFit: "contain",
          }}
        />
      </div>

      {/* Main content */}
      <div
        style={{
          position: "absolute",
          top: "45%",
          left: "50%",
          transform: "translate(-50%, -50%)",
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          gap: 30,
        }}
      >
        {/* Logo with glow */}
        <div
          style={{
            position: "relative",
            transform: `scale(${logoScale})`,
            opacity: logoOpacity,
          }}
        >
          {/* Glow behind logo */}
          <div
            style={{
              position: "absolute",
              inset: -40,
              background: `radial-gradient(circle, rgba(11,19,43,${glowPulse}) 0%, transparent 70%)`,
              filter: "blur(30px)",
              borderRadius: "50%",
            }}
          />
          <Img
            src={staticFile("app_icon.png")}
            style={{
              width: 160,
              height: 160,
              borderRadius: 36,
              boxShadow: `
                0 20px 60px rgba(11, 19, 43, 0.2),
                0 8px 24px rgba(11, 19, 43, 0.15)
              `,
            }}
          />
        </div>

        {/* Brand name animated */}
        <AnimatedText
          text="RYZE"
          fontSize={72}
          fontWeight={900}
          color="#0B132B"
          delay={20}
          staggerDelay={4}
          animationType="scale"
          style={{
            letterSpacing: 12,
          }}
        />

        {/* Tagline */}
        <div
          style={{
            opacity: interpolate(frame, [45, 65], [0, 1], {
              extrapolateLeft: "clamp",
              extrapolateRight: "clamp",
            }),
            transform: `translateY(${interpolate(frame, [45, 65], [15, 0], {
              extrapolateLeft: "clamp",
              extrapolateRight: "clamp",
            })}px)`,
          }}
        >
          <span
            style={{
              fontSize: 26,
              fontWeight: 500,
              color: "#64748B",
              letterSpacing: 2,
            }}
          >
            Planificateur IA
          </span>
        </div>
      </div>
    </AbsoluteFill>
  );
};
