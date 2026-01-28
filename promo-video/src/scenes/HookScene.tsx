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

const { fontFamily } = loadFont("normal", {
  weights: ["400", "500", "600", "700", "800", "900"],
  subsets: ["latin"],
});

const painPoints = [
  "Tu sais pas quoi manger ?",
  "Pas le temps de planifier ?",
  "Tes objectifs avancent pas ?",
];

export const HookScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Fade in/out
  const fadeIn = interpolate(frame, [0, 15], [0, 1], {
    extrapolateRight: "clamp",
  });
  const fadeOut = interpolate(frame, [280, 300], [1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  // Each pain point appears one after another and STAYS visible
  const painPointStarts = [20, 60, 100]; // staggered entrances

  // Animated lines
  const lines = Array.from({ length: 8 }, (_, i) => ({
    x: 80 + i * 120,
    delay: 30 + i * 10,
    length: 60 + (i % 3) * 40,
  }));

  // Floating dots pattern
  const dots = Array.from({ length: 15 }, (_, i) => ({
    x: 50 + (i % 5) * 220,
    y: 200 + Math.floor(i / 5) * 500,
    delay: 15 + i * 5,
  }));

  // Pulsing circles for emphasis
  const pulseCircles = [
    { x: 100, y: 400, delay: 25 },
    { x: 980, y: 600, delay: 45 },
    { x: 150, y: 1400, delay: 65 },
  ];

  // Solution reveal - after all pain points are shown
  const solutionStart = 180;
  const solutionSpring = spring({
    frame: frame - solutionStart,
    fps,
    config: {
      damping: 14,
      stiffness: 120,
      mass: 0.8,
    },
  });

  return (
    <AbsoluteFill
      style={{
        background: "#FFFFFF",
        fontFamily,
        opacity: fadeIn * fadeOut,
      }}
    >
      {/* Subtle background accent */}
      <div
        style={{
          position: "absolute",
          inset: 0,
          background: "radial-gradient(ellipse at 50% 40%, rgba(11,19,43,0.02) 0%, transparent 70%)",
        }}
      />

      {/* Animated vertical lines */}
      {lines.map((line, i) => {
        const lineProgress = interpolate(
          frame - line.delay,
          [0, 30],
          [0, 1],
          { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
        );
        const lineHeight = interpolate(lineProgress, [0, 1], [0, line.length]);
        const lineOpacity = interpolate(
          frame - line.delay,
          [0, 20, 250, 280],
          [0, 0.1, 0.1, 0],
          { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
        );

        if (frame < line.delay) return null;

        return (
          <div
            key={`line-${i}`}
            style={{
              position: "absolute",
              left: line.x,
              top: 150,
              width: 2,
              height: lineHeight,
              background: "linear-gradient(180deg, #0B132B, transparent)",
              opacity: lineOpacity,
              borderRadius: 1,
            }}
          />
        );
      })}

      {/* Floating dots */}
      {dots.map((dot, i) => {
        const dotProgress = frame - dot.delay;
        const floatY = Math.sin(dotProgress / 30) * 15;
        const floatX = Math.cos(dotProgress / 40) * 10;
        const dotOpacity = interpolate(
          dotProgress,
          [0, 20, 250, 280],
          [0, 0.15, 0.15, 0],
          { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
        );

        if (frame < dot.delay) return null;

        return (
          <div
            key={`dot-${i}`}
            style={{
              position: "absolute",
              left: dot.x + floatX,
              top: dot.y + floatY,
              width: 8,
              height: 8,
              borderRadius: "50%",
              background: i % 2 === 0 ? "#0B132B" : "transparent",
              border: i % 2 === 0 ? "none" : "2px solid #0B132B",
              opacity: dotOpacity,
            }}
          />
        );
      })}

      {/* Pulsing emphasis circles */}
      {pulseCircles.map((circle, i) => {
        const pulseProgress = ((frame - circle.delay) % 60) / 60;
        const pulseScale = interpolate(pulseProgress, [0, 1], [0.5, 1.5]);
        const pulseOpacity = interpolate(pulseProgress, [0, 0.5, 1], [0.2, 0.1, 0]);

        if (frame < circle.delay) return null;

        return (
          <div
            key={`pulse-${i}`}
            style={{
              position: "absolute",
              left: circle.x,
              top: circle.y,
              width: 60,
              height: 60,
              borderRadius: "50%",
              border: "2px solid #0B132B",
              opacity: pulseOpacity,
              transform: `translate(-50%, -50%) scale(${pulseScale})`,
            }}
          />
        );
      })}

      {/* Panda with bubble in top right */}
      <div
        style={{
          position: "absolute",
          top: 40,
          right: -60,
          opacity: interpolate(frame, [5, 25], [0, 1], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          }),
          transform: `scale(${interpolate(frame, [5, 25], [0.8, 1], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          })})`,
        }}
      >
        <Img
          src={staticFile("coach_ryze_tutorial_bubble.png")}
          style={{
            width: 520,
            height: 520,
            objectFit: "contain",
          }}
        />
      </div>

      {/* Pain points container - stacked vertically */}
      <div
        style={{
          position: "absolute",
          top: 280,
          left: 0,
          right: 0,
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          gap: 28,
        }}
      >
        {painPoints.map((text, index) => {
          const startFrame = painPointStarts[index];

          // Entrance spring - each one appears and stays
          const entranceSpring = spring({
            frame: frame - startFrame,
            fps,
            config: {
              damping: 14,
              stiffness: 150,
              mass: 0.7,
            },
          });

          const scale = interpolate(entranceSpring, [0, 1], [0.9, 1]);
          const x = interpolate(entranceSpring, [0, 1], [-60, 0]);
          const opacity = interpolate(entranceSpring, [0, 0.5], [0, 1], {
            extrapolateRight: "clamp",
          });

          return (
            <div
              key={index}
              style={{
                textAlign: "center",
                opacity,
                transform: `translateX(${x}px) scale(${scale})`,
              }}
            >
              <span
                style={{
                  fontSize: 46,
                  fontWeight: 800,
                  color: "#0B132B",
                  lineHeight: 1.3,
                }}
              >
                {text}
              </span>
            </div>
          );
        })}
      </div>

      {/* Solution text */}
      <div
        style={{
          position: "absolute",
          bottom: 260,
          left: 0,
          right: 0,
          textAlign: "center",
          opacity: interpolate(solutionSpring, [0, 0.5], [0, 1], {
            extrapolateRight: "clamp",
          }),
          transform: `translateY(${interpolate(solutionSpring, [0, 1], [30, 0])}px)`,
        }}
      >
        <div
          style={{
            fontSize: 28,
            fontWeight: 500,
            color: "#64748B",
            marginBottom: 12,
          }}
        >
          Et si...
        </div>
        <div
          style={{
            fontSize: 44,
            fontWeight: 900,
            color: "#0B132B",
            position: "relative",
            display: "inline-block",
          }}
        >
          {/* Glow effect behind text */}
          <div
            style={{
              position: "absolute",
              inset: -20,
              background: "radial-gradient(ellipse, rgba(11,19,43,0.08) 0%, transparent 70%)",
              filter: "blur(15px)",
            }}
          />
          <span style={{ position: "relative" }}>
            Ryze s'en occupait ?
          </span>
        </div>
      </div>

      {/* Decorative line accent */}
      <div
        style={{
          position: "absolute",
          bottom: 180,
          left: "50%",
          transform: "translateX(-50%)",
          width: interpolate(solutionSpring, [0, 1], [0, 100]),
          height: 4,
          background: "linear-gradient(90deg, #0B132B, #1C2951)",
          borderRadius: 2,
          opacity: solutionSpring,
        }}
      />
    </AbsoluteFill>
  );
};
