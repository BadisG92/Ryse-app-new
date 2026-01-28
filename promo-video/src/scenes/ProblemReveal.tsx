import {
  AbsoluteFill,
  useCurrentFrame,
  useVideoConfig,
  interpolate,
  Easing,
} from "remotion";
import { loadFont } from "@remotion/google-fonts/Inter";

const { fontFamily } = loadFont("normal", {
  weights: ["400", "500", "600", "700"],
  subsets: ["latin"],
});

export const ProblemReveal: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Fade in from previous scene
  const fadeIn = interpolate(frame, [0, 20], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  // Fade out to next scene
  const fadeOut = interpolate(frame, [100, 120], [1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  const opacity = fadeIn * fadeOut;

  // Text lines with staggered reveal
  const lines = [
    { text: "Planifier sa semaine", delay: 10 },
    { text: "c'est compliqué.", delay: 25, highlight: true },
  ];

  // Solution reveal
  const solutionReveal = interpolate(frame, [55, 80], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.bezier(0.16, 1, 0.3, 1),
  });

  // Glitch effect on "compliqué"
  const glitchOffset = frame > 30 && frame < 35
    ? Math.sin(frame * 50) * 3
    : 0;

  return (
    <AbsoluteFill
      style={{
        background: "#FFFFFF",
        fontFamily,
        opacity,
      }}
    >
      {/* Subtle grid pattern */}
      <div
        style={{
          position: "absolute",
          inset: 0,
          opacity: 0.03,
          backgroundImage: `
            linear-gradient(rgba(11,19,43,1) 1px, transparent 1px),
            linear-gradient(90deg, rgba(11,19,43,1) 1px, transparent 1px)
          `,
          backgroundSize: "60px 60px",
        }}
      />

      {/* Main text container */}
      <div
        style={{
          position: "absolute",
          top: "35%",
          left: 0,
          right: 0,
          padding: "0 80px",
        }}
      >
        {lines.map((line, i) => {
          const lineReveal = interpolate(frame, [line.delay, line.delay + 20], [0, 1], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
            easing: Easing.bezier(0.16, 1, 0.3, 1),
          });

          const lineY = interpolate(lineReveal, [0, 1], [60, 0]);
          const lineOpacity = interpolate(lineReveal, [0, 0.3], [0, 1], {
            extrapolateRight: "clamp",
          });

          // Strike through animation for "compliqué"
          const strikeWidth = line.highlight
            ? interpolate(frame, [50, 65], [0, 100], {
                extrapolateLeft: "clamp",
                extrapolateRight: "clamp",
              })
            : 0;

          return (
            <div
              key={i}
              style={{
                fontSize: 64,
                fontWeight: line.highlight ? 700 : 500,
                color: "#0B132B",
                lineHeight: 1.2,
                transform: `translateY(${lineY}px) translateX(${line.highlight ? glitchOffset : 0}px)`,
                opacity: lineOpacity,
                position: "relative",
                display: "inline-block",
                marginBottom: 10,
              }}
            >
              {line.text}
              {line.highlight && (
                <div
                  style={{
                    position: "absolute",
                    top: "55%",
                    left: 0,
                    height: 6,
                    width: `${strikeWidth}%`,
                    background: "#EF4444",
                    borderRadius: 3,
                  }}
                />
              )}
            </div>
          );
        })}
      </div>

      {/* Solution text */}
      <div
        style={{
          position: "absolute",
          top: "58%",
          left: 0,
          right: 0,
          padding: "0 80px",
          opacity: solutionReveal,
          transform: `translateY(${interpolate(solutionReveal, [0, 1], [40, 0])}px)`,
        }}
      >
        <div
          style={{
            fontSize: 48,
            fontWeight: 600,
            color: "#0B132B",
            marginBottom: 20,
          }}
        >
          Jusqu'à maintenant.
        </div>
      </div>

      {/* Animated accent line */}
      <div
        style={{
          position: "absolute",
          top: "75%",
          left: "50%",
          transform: "translateX(-50%)",
          width: interpolate(frame, [70, 95], [0, 300], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
            easing: Easing.out(Easing.quad),
          }),
          height: 4,
          background: "#0B132B",
          borderRadius: 2,
        }}
      />
    </AbsoluteFill>
  );
};
