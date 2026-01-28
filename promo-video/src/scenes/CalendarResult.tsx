import {
  AbsoluteFill,
  Img,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
  spring,
  interpolate,
  Easing,
} from "remotion";
import { loadFont } from "@remotion/google-fonts/Inter";
import { SuccessBadge } from "../components/GlassCard";

const { fontFamily } = loadFont("normal", {
  weights: ["400", "500", "600", "700", "800", "900"],
  subsets: ["latin"],
});

export const CalendarResult: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Fade transitions
  const fadeIn = interpolate(frame, [0, 25], [0, 1], {
    extrapolateRight: "clamp",
  });
  const fadeOut = interpolate(frame, [280, 300], [1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  // Phone entrance
  const phoneSpring = spring({
    frame,
    fps,
    config: {
      damping: 16,
      stiffness: 100,
      mass: 0.9,
    },
  });

  const phoneScale = interpolate(phoneSpring, [0, 1], [0.85, 1]);
  const phoneOpacity = interpolate(phoneSpring, [0, 0.4], [0, 1], {
    extrapolateRight: "clamp",
  });

  // Zoom to calendar section
  const zoomProgress = interpolate(frame, [60, 140], [1, 1.6], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.inOut(Easing.quad),
  });

  const panY = interpolate(frame, [60, 140], [0, -200], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.inOut(Easing.quad),
  });

  // Floating
  const floatY = Math.sin(frame / 45) * 3;

  // Checkmarks animation (one by one)
  const checkmarks = ["J", "V", "S", "D"];
  const checkmarkStarts = [120, 140, 160, 180];

  // Blue confetti - more particles
  const confetti = Array.from({ length: 35 }, (_, i) => ({
    x: 100 + Math.random() * 880,
    startY: 300 + Math.random() * 300,
    delay: 140 + i * 3,
    speed: 2.5 + Math.random() * 2,
    size: 6 + Math.random() * 10,
    rotation: Math.random() * 360,
    rotationSpeed: 2 + Math.random() * 4,
  }));

  // Success burst particles
  const successBurst = Array.from({ length: 20 }, (_, i) => ({
    angle: (i / 20) * Math.PI * 2,
    speed: 3 + (i % 4) * 1,
    size: 5 + (i % 3) * 3,
    delay: 180,
  }));

  // Celebration sparkles
  const celebrationSparkles = Array.from({ length: 15 }, (_, i) => ({
    x: 150 + (i % 5) * 200,
    y: 250 + Math.floor(i / 5) * 500,
    delay: 160 + i * 8,
    size: 12 + (i % 3) * 6,
  }));

  // Rising celebration lines
  const celebrationLines = Array.from({ length: 8 }, (_, i) => ({
    x: 100 + i * 130,
    delay: 200 + i * 10,
    height: 80 + (i % 3) * 40,
  }));

  return (
    <AbsoluteFill
      style={{
        background: "linear-gradient(180deg, #FFFFFF 0%, #F8FAFC 100%)",
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
          opacity: interpolate(frame, [20, 45], [0, 1], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          }),
          transform: `translateY(${interpolate(frame, [20, 45], [20, 0], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          })}px)`,
        }}
      >
        <div
          style={{
            fontSize: 44,
            fontWeight: 900,
            color: "#0B132B",
            marginBottom: 10,
          }}
        >
          Ta semaine est prête
        </div>
        <div
          style={{
            fontSize: 22,
            fontWeight: 500,
            color: "#64748B",
          }}
        >
          Tous tes repas sont planifiés
        </div>
      </div>

      {/* Phone with dashboard screenshot */}
      <div
        style={{
          position: "absolute",
          top: "50%",
          left: "50%",
          transform: `translate(-50%, -50%) scale(${phoneScale * zoomProgress}) translateY(${panY + floatY}px)`,
          opacity: phoneOpacity,
        }}
      >
        {/* Phone shadow */}
        <div
          style={{
            position: "absolute",
            bottom: -50,
            left: "50%",
            transform: "translateX(-50%)",
            width: 280,
            height: 40,
            background: "radial-gradient(ellipse, rgba(11,19,43,0.2) 0%, transparent 70%)",
            filter: "blur(18px)",
          }}
        />

        {/* Phone frame */}
        <div
          style={{
            width: 380,
            height: 820,
            background: "linear-gradient(145deg, #2a2a2a 0%, #1a1a1a 50%, #0f0f0f 100%)",
            borderRadius: 55,
            padding: 10,
            boxShadow: `
              0 50px 100px rgba(11,19,43,0.25),
              0 20px 40px rgba(11,19,43,0.15),
              inset 0 1px 0 rgba(255,255,255,0.1)
            `,
            position: "relative",
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
              src={staticFile("planner_04.png")}
              style={{
                width: "100%",
                height: "100%",
                objectFit: "cover",
              }}
            />
          </div>

          {/* Dynamic Island */}
          <div
            style={{
              position: "absolute",
              top: 20,
              left: "50%",
              transform: "translateX(-50%)",
              width: 126,
              height: 37,
              background: "#000",
              borderRadius: 20,
              zIndex: 10,
            }}
          />
        </div>
      </div>

      {/* Animated checkmarks overlay - properly aligned */}
      <div
        style={{
          position: "absolute",
          bottom: 320,
          left: "50%",
          transform: "translateX(-50%)",
          display: "flex",
          justifyContent: "center",
          alignItems: "flex-start",
          gap: 24,
          zIndex: 15,
        }}
      >
        {checkmarks.map((day, index) => {
          const checkSpring = spring({
            frame: frame - checkmarkStarts[index],
            fps,
            config: {
              damping: 12,
              stiffness: 180,
            },
          });

          const scale = interpolate(checkSpring, [0, 1], [0, 1]);
          const opacity = interpolate(checkSpring, [0, 0.3], [0, 1], {
            extrapolateRight: "clamp",
          });

          return (
            <div
              key={day}
              style={{
                display: "flex",
                flexDirection: "column",
                alignItems: "center",
                gap: 8,
                opacity,
                transform: `scale(${scale})`,
                width: 56,
              }}
            >
              <div
                style={{
                  width: 48,
                  height: 48,
                  borderRadius: "50%",
                  background: "#10B981",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  boxShadow: "0 6px 16px rgba(16, 185, 129, 0.35)",
                }}
              >
                <svg
                  width="24"
                  height="24"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="#FFFFFF"
                  strokeWidth="3"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                >
                  <polyline points="20 6 9 17 4 12" />
                </svg>
              </div>
              <span
                style={{
                  fontSize: 16,
                  fontWeight: 700,
                  color: "#0B132B",
                  textAlign: "center",
                }}
              >
                {day}
              </span>
            </div>
          );
        })}
      </div>

      {/* Panda congratulations - bottom left */}
      <div
        style={{
          position: "absolute",
          bottom: -60,
          left: -40,
          opacity: interpolate(frame, [180, 210], [0, 1], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          }),
          transform: `translateY(${interpolate(frame, [180, 210], [40, 0], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          })}px) rotate(-3deg)`,
        }}
      >
        <Img
          src={staticFile("coach_ryze_congratulations.png")}
          style={{
            width: 480,
            height: 480,
            objectFit: "contain",
          }}
        />
      </div>

      {/* Success burst particles from center */}
      {successBurst.map((p, i) => {
        const burstProgress = (frame - p.delay) / 50;
        if (frame < p.delay || burstProgress > 1.2) return null;

        const distance = burstProgress * 250 * p.speed;
        const x = 540 + Math.cos(p.angle) * distance;
        const y = 600 + Math.sin(p.angle) * distance * 0.7;
        const burstOpacity = interpolate(
          burstProgress,
          [0, 0.15, 0.8, 1.2],
          [0, 0.7, 0.4, 0],
          { extrapolateRight: "clamp" }
        );

        return (
          <div
            key={`burst-${i}`}
            style={{
              position: "absolute",
              left: x,
              top: y,
              width: p.size,
              height: p.size,
              borderRadius: "50%",
              background: i % 3 === 0 ? "#10B981" : i % 3 === 1 ? "#0B132B" : "#1C2951",
              opacity: burstOpacity,
              transform: "translate(-50%, -50%)",
              boxShadow: i % 3 === 0 ? "0 0 10px rgba(16,185,129,0.4)" : "none",
            }}
          />
        );
      })}

      {/* Celebration sparkles */}
      {celebrationSparkles.map((sparkle, i) => {
        const sparkleProgress = frame - sparkle.delay;
        const twinkle = Math.sin(sparkleProgress / 8 + i * 2) * 0.5 + 0.5;
        const sparkleOpacity = interpolate(
          sparkleProgress,
          [0, 20, 100, 130],
          [0, 0.7 * twinkle, 0.7 * twinkle, 0],
          { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
        );
        const sparkleScale = interpolate(
          sparkleProgress,
          [0, 20],
          [0, 1],
          { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
        );

        if (frame < sparkle.delay) return null;

        return (
          <div
            key={`sparkle-${i}`}
            style={{
              position: "absolute",
              left: sparkle.x,
              top: sparkle.y + Math.sin(sparkleProgress / 20) * 10,
              opacity: sparkleOpacity,
              transform: `scale(${sparkleScale}) rotate(${sparkleProgress * 2}deg)`,
            }}
          >
            {/* 4-point star */}
            <svg width={sparkle.size} height={sparkle.size} viewBox="0 0 24 24">
              <path
                d="M12 0L14 10L24 12L14 14L12 24L10 14L0 12L10 10Z"
                fill={i % 2 === 0 ? "#10B981" : "#0B132B"}
              />
            </svg>
          </div>
        );
      })}

      {/* Celebration rising lines */}
      {celebrationLines.map((line, i) => {
        const lineProgress = interpolate(
          frame - line.delay,
          [0, 25],
          [0, 1],
          { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
        );
        const lineOpacity = interpolate(
          frame - line.delay,
          [0, 15, 60, 80],
          [0, 0.4, 0.4, 0],
          { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
        );

        if (frame < line.delay) return null;

        return (
          <div
            key={`line-${i}`}
            style={{
              position: "absolute",
              left: line.x,
              bottom: 200,
              width: 3,
              height: line.height * lineProgress,
              background: `linear-gradient(0deg, ${i % 2 === 0 ? "#10B981" : "#0B132B"}, transparent)`,
              opacity: lineOpacity,
              borderRadius: 2,
            }}
          />
        );
      })}

      {/* Blue confetti */}
      {confetti.map((c, i) => {
        if (frame < c.delay) return null;

        const progress = (frame - c.delay) / 50;
        const y = c.startY - progress * 250 * c.speed;
        const x = c.x + Math.sin(progress * 4 + i) * 40;
        const rotation = c.rotation + progress * 180 * c.rotationSpeed;
        const opacity = interpolate(
          progress,
          [0, 0.15, 0.7, 1],
          [0, 0.85, 0.6, 0],
          { extrapolateRight: "clamp" }
        );

        return (
          <div
            key={i}
            style={{
              position: "absolute",
              left: x,
              top: y,
              width: c.size,
              height: c.size * 0.6,
              background: i % 3 === 0 ? "#10B981" : i % 3 === 1 ? "#0B132B" : "#1C2951",
              borderRadius: 2,
              opacity,
              transform: `rotate(${rotation}deg)`,
            }}
          />
        );
      })}

      {/* Success badge */}
      <div
        style={{
          position: "absolute",
          bottom: 140,
          left: "50%",
          transform: "translateX(-50%)",
        }}
      >
        <SuccessBadge
          text="4 jours planifiés en 10s"
          delay={200}
        />
      </div>
    </AbsoluteFill>
  );
};
