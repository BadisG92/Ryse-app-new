import {
  AbsoluteFill,
  Img,
  staticFile,
  useCurrentFrame,
  interpolate,
  spring,
  useVideoConfig,
  Easing,
} from "remotion";
import { loadFont } from "@remotion/google-fonts/Inter";

const { fontFamily } = loadFont("normal", {
  weights: ["400", "500", "600", "700"],
  subsets: ["latin"],
});

export const MealsReveal: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Fade transitions
  const fadeIn = interpolate(frame, [0, 30], [0, 1], {
    extrapolateRight: "clamp",
  });
  const fadeOut = interpolate(frame, [270, 300], [1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  // Zoom into meals section of screenshot
  const zoomProgress = interpolate(frame, [0, 60], [0, 1], {
    extrapolateRight: "clamp",
    easing: Easing.bezier(0.16, 1, 0.3, 1),
  });

  const phoneScale = interpolate(zoomProgress, [0, 1], [1, 2.2]);
  const phoneY = interpolate(zoomProgress, [0, 1], [0, -350]);

  // Highlight cards animation
  const card1Highlight = interpolate(frame, [80, 100, 130, 150], [0, 1, 1, 0.3], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const card2Highlight = interpolate(frame, [120, 140, 170, 190], [0, 1, 1, 0.3], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });
  const card3Highlight = interpolate(frame, [160, 180, 210, 230], [0, 1, 1, 0.3], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  // Text overlay
  const titleOpacity = interpolate(frame, [30, 50], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  const subtitleOpacity = interpolate(frame, [200, 220], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  return (
    <AbsoluteFill
      style={{
        background: "#FFFFFF",
        fontFamily,
        opacity: fadeIn * fadeOut,
        overflow: "hidden",
      }}
    >
      {/* Title */}
      <div
        style={{
          position: "absolute",
          top: 100,
          left: 0,
          right: 0,
          textAlign: "center",
          zIndex: 20,
          opacity: titleOpacity,
        }}
      >
        <div
          style={{
            fontSize: 42,
            fontWeight: 700,
            color: "#0B132B",
            marginBottom: 10,
          }}
        >
          Des repas personnalisés
        </div>
        <div
          style={{
            fontSize: 22,
            color: "#64748B",
          }}
        >
          Calories et macros calculées
        </div>
      </div>

      {/* Phone with zoomed screenshot */}
      <div
        style={{
          position: "absolute",
          top: "50%",
          left: "50%",
          transform: `translate(-50%, -50%) scale(${phoneScale}) translateY(${phoneY}px)`,
        }}
      >
        {/* Phone frame */}
        <div
          style={{
            width: 380,
            height: 820,
            background: "#1a1a1a",
            borderRadius: 55,
            padding: 10,
            boxShadow: "0 50px 100px rgba(0,0,0,0.3)",
          }}
        >
          <div
            style={{
              width: "100%",
              height: "100%",
              borderRadius: 46,
              overflow: "hidden",
              background: "#FFF",
            }}
          >
            <Img
              src={staticFile("planner_03.png")}
              style={{
                width: "100%",
                height: "100%",
                objectFit: "cover",
              }}
            />
          </div>
        </div>
      </div>

      {/* Highlight overlays for meal cards */}
      <div
        style={{
          position: "absolute",
          top: "50%",
          left: "50%",
          transform: "translate(-50%, -50%)",
          pointerEvents: "none",
          zIndex: 10,
        }}
      >
        {/* Card 1 highlight */}
        <div
          style={{
            position: "absolute",
            top: 80,
            left: -160,
            width: 320,
            height: 80,
            border: `3px solid rgba(16, 185, 129, ${card1Highlight})`,
            borderRadius: 16,
            boxShadow: `0 0 20px rgba(16, 185, 129, ${card1Highlight * 0.5})`,
          }}
        />

        {/* Card 2 highlight */}
        <div
          style={{
            position: "absolute",
            top: 175,
            left: -160,
            width: 320,
            height: 80,
            border: `3px solid rgba(59, 130, 246, ${card2Highlight})`,
            borderRadius: 16,
            boxShadow: `0 0 20px rgba(59, 130, 246, ${card2Highlight * 0.5})`,
          }}
        />

        {/* Card 3 highlight */}
        <div
          style={{
            position: "absolute",
            top: 270,
            left: -160,
            width: 320,
            height: 80,
            border: `3px solid rgba(139, 92, 246, ${card3Highlight})`,
            borderRadius: 16,
            boxShadow: `0 0 20px rgba(139, 92, 246, ${card3Highlight * 0.5})`,
          }}
        />
      </div>

      {/* Bottom subtitle */}
      <div
        style={{
          position: "absolute",
          bottom: 120,
          left: 0,
          right: 0,
          textAlign: "center",
          opacity: subtitleOpacity,
        }}
      >
        <div
          style={{
            display: "inline-flex",
            alignItems: "center",
            gap: 10,
            background: "#10B981",
            color: "#FFFFFF",
            padding: "14px 28px",
            borderRadius: 30,
            fontSize: 20,
            fontWeight: 600,
          }}
        >
          <span>✓</span>
          <span>4 jours planifiés en 10 secondes</span>
        </div>
      </div>
    </AbsoluteFill>
  );
};
