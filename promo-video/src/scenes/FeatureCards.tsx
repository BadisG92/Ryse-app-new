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
  weights: ["400", "500", "600", "700"],
  subsets: ["latin"],
});

export const FeatureCards: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const features = [
    {
      icon: "🍎",
      title: "Nutrition",
      desc: "Repas personnalisés",
      color: "#10B981",
      image: "ryze_nutrition.png",
    },
    {
      icon: "💪",
      title: "Sport",
      desc: "Séances sur mesure",
      color: "#3B82F6",
      image: "ryze_workout.png",
    },
    {
      icon: "🎯",
      title: "Objectifs",
      desc: "Suivi intelligent",
      color: "#8B5CF6",
      image: "ryze_happy.png",
    },
  ];

  // Fade in
  const fadeIn = interpolate(frame, [0, 15], [0, 1], {
    extrapolateRight: "clamp",
  });

  // Fade out
  const fadeOut = interpolate(frame, [65, 80], [1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  return (
    <AbsoluteFill
      style={{
        background: "#FFFFFF",
        fontFamily,
        opacity: fadeIn * fadeOut,
      }}
    >
      {/* Title */}
      <div
        style={{
          position: "absolute",
          top: 180,
          left: 0,
          right: 0,
          textAlign: "center",
          opacity: interpolate(frame, [5, 20], [0, 1], {
            extrapolateRight: "clamp",
          }),
          transform: `translateY(${interpolate(frame, [5, 20], [20, 0], {
            extrapolateRight: "clamp",
          })}px)`,
        }}
      >
        <div
          style={{
            fontSize: 48,
            fontWeight: 700,
            color: "#0B132B",
            marginBottom: 10,
          }}
        >
          Tout-en-un
        </div>
        <div
          style={{
            fontSize: 22,
            color: "#64748B",
          }}
        >
          Une seule app pour tous tes objectifs
        </div>
      </div>

      {/* Feature cards */}
      <div
        style={{
          position: "absolute",
          top: 380,
          left: 0,
          right: 0,
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          gap: 24,
          padding: "0 60px",
        }}
      >
        {features.map((feature, i) => {
          const delay = 10 + i * 10;
          const cardSpring = spring({
            frame: frame - delay,
            fps,
            config: { damping: 15, stiffness: 100 },
          });

          const cardOpacity = interpolate(cardSpring, [0, 1], [0, 1], {
            extrapolateLeft: "clamp",
          });
          const cardX = interpolate(cardSpring, [0, 1], [i % 2 === 0 ? -80 : 80, 0], {
            extrapolateLeft: "clamp",
          });
          const cardScale = interpolate(cardSpring, [0, 1], [0.9, 1], {
            extrapolateLeft: "clamp",
          });

          return (
            <div
              key={i}
              style={{
                width: "100%",
                maxWidth: 400,
                background: "#FFFFFF",
                borderRadius: 24,
                padding: "24px 28px",
                display: "flex",
                alignItems: "center",
                gap: 20,
                boxShadow: "0 10px 40px rgba(11,19,43,0.08), 0 0 0 1px rgba(11,19,43,0.05)",
                opacity: cardOpacity,
                transform: `translateX(${cardX}px) scale(${cardScale})`,
              }}
            >
              {/* Avatar */}
              <div
                style={{
                  width: 70,
                  height: 70,
                  borderRadius: 18,
                  background: `${feature.color}15`,
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  flexShrink: 0,
                  overflow: "hidden",
                }}
              >
                <Img
                  src={staticFile(feature.image)}
                  style={{
                    width: 55,
                    height: 55,
                    objectFit: "contain",
                  }}
                />
              </div>

              {/* Text */}
              <div style={{ flex: 1 }}>
                <div
                  style={{
                    fontSize: 24,
                    fontWeight: 700,
                    color: "#0B132B",
                    marginBottom: 4,
                  }}
                >
                  {feature.title}
                </div>
                <div
                  style={{
                    fontSize: 16,
                    color: "#64748B",
                  }}
                >
                  {feature.desc}
                </div>
              </div>

              {/* Accent */}
              <div
                style={{
                  width: 4,
                  height: 40,
                  background: feature.color,
                  borderRadius: 2,
                }}
              />
            </div>
          );
        })}
      </div>
    </AbsoluteFill>
  );
};
