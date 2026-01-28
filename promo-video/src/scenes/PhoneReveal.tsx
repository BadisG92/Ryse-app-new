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
import { PhoneMockup } from "../components/PhoneMockup";
import { GradientBadge } from "../components/GlassCard";

const { fontFamily } = loadFont("normal", {
  weights: ["400", "500", "600", "700", "800", "900"],
  subsets: ["latin"],
});

export const PhoneReveal: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Fade transitions
  const fadeIn = interpolate(frame, [0, 20], [0, 1], {
    extrapolateRight: "clamp",
  });
  const fadeOut = interpolate(frame, [160, 180], [1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  // Phone entrance from bottom - energetic spring
  const phoneSpring = spring({
    frame,
    fps,
    config: {
      damping: 14,
      stiffness: 120,
      mass: 1,
    },
  });

  const phoneY = interpolate(phoneSpring, [0, 1], [800, 100]);
  const phoneScale = interpolate(phoneSpring, [0, 1], [0.9, 1]);
  const phoneOpacity = interpolate(phoneSpring, [0, 0.3], [0, 1], {
    extrapolateRight: "clamp",
  });

  // Title animation
  const titleSpring = spring({
    frame: frame - 30,
    fps,
    config: {
      damping: 15,
      stiffness: 150,
    },
  });

  // Sparkles around phone
  const sparkles = Array.from({ length: 12 }, (_, i) => ({
    angle: (i / 12) * Math.PI * 2,
    distance: 280 + (i % 3) * 40,
    size: 6 + (i % 3) * 4,
    delay: 20 + i * 5,
  }));

  // Animated arcs
  const arcs = [
    { startAngle: -30, endAngle: 30, radius: 350, delay: 40 },
    { startAngle: 150, endAngle: 210, radius: 320, delay: 50 },
  ];

  // Rising particles
  const risingParticles = Array.from({ length: 10 }, (_, i) => ({
    x: 300 + i * 80,
    startY: 1800,
    speed: 2 + (i % 3) * 0.5,
    delay: 30 + i * 8,
    size: 5 + (i % 3) * 3,
  }));

  return (
    <AbsoluteFill
      style={{
        background: "#FFFFFF",
        fontFamily,
        opacity: fadeIn * fadeOut,
      }}
    >
      {/* Radial gradient for depth */}
      <div
        style={{
          position: "absolute",
          inset: 0,
          background: "radial-gradient(ellipse at 50% 70%, rgba(11,19,43,0.04) 0%, transparent 60%)",
        }}
      />

      {/* Sparkles around phone */}
      {sparkles.map((sparkle, i) => {
        const sparkleProgress = frame - sparkle.delay;
        const twinkle = Math.sin(sparkleProgress / 10 + i) * 0.5 + 0.5;
        const orbitOffset = sparkleProgress * 0.02;
        const x = 540 + Math.cos(sparkle.angle + orbitOffset) * sparkle.distance;
        const y = 700 + Math.sin(sparkle.angle + orbitOffset) * sparkle.distance * 0.6;
        const sparkleOpacity = interpolate(
          sparkleProgress,
          [0, 15, 140, 160],
          [0, 0.6 * twinkle, 0.6 * twinkle, 0],
          { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
        );

        if (frame < sparkle.delay) return null;

        return (
          <div
            key={`sparkle-${i}`}
            style={{
              position: "absolute",
              left: x,
              top: y,
              width: sparkle.size,
              height: sparkle.size,
              transform: "translate(-50%, -50%) rotate(45deg)",
            }}
          >
            {/* 4-point star sparkle */}
            <div
              style={{
                position: "absolute",
                width: "100%",
                height: 2,
                top: "50%",
                left: 0,
                transform: "translateY(-50%)",
                background: "#0B132B",
                opacity: sparkleOpacity,
                borderRadius: 1,
              }}
            />
            <div
              style={{
                position: "absolute",
                width: 2,
                height: "100%",
                top: 0,
                left: "50%",
                transform: "translateX(-50%)",
                background: "#0B132B",
                opacity: sparkleOpacity,
                borderRadius: 1,
              }}
            />
          </div>
        );
      })}

      {/* Rising particles */}
      {risingParticles.map((p, i) => {
        const particleProgress = frame - p.delay;
        const y = p.startY - particleProgress * p.speed;
        const wobbleX = Math.sin(particleProgress / 20 + i) * 15;
        const particleOpacity = interpolate(
          particleProgress,
          [0, 20, 120, 150],
          [0, 0.4, 0.4, 0],
          { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
        );

        if (frame < p.delay || y < 0) return null;

        return (
          <div
            key={`rising-${i}`}
            style={{
              position: "absolute",
              left: p.x + wobbleX,
              top: y,
              width: p.size,
              height: p.size,
              borderRadius: "50%",
              background: i % 2 === 0 ? "#0B132B" : "#1C2951",
              opacity: particleOpacity,
            }}
          />
        );
      })}

      {/* Panda chef in bottom left */}
      <div
        style={{
          position: "absolute",
          bottom: -60,
          left: -60,
          opacity: interpolate(frame, [60, 90], [0, 1], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          }),
          transform: `translateY(${interpolate(frame, [60, 90], [50, 0], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          })}px) rotate(-8deg)`,
        }}
      >
        <Img
          src={staticFile("coach_ryze_chef_avatar.png")}
          style={{
            width: 480,
            height: 480,
            objectFit: "contain",
          }}
        />
      </div>

      {/* Panda nutrition in bottom right */}
      <div
        style={{
          position: "absolute",
          bottom: -40,
          right: -60,
          opacity: interpolate(frame, [70, 100], [0, 1], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          }),
          transform: `translateY(${interpolate(frame, [70, 100], [50, 0], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          })}px) rotate(8deg)`,
        }}
      >
        <Img
          src={staticFile("coach_ryze_nutrition_avatar.png")}
          style={{
            width: 440,
            height: 440,
            objectFit: "contain",
          }}
        />
      </div>

      {/* Title */}
      <div
        style={{
          position: "absolute",
          top: 120,
          left: 0,
          right: 0,
          textAlign: "center",
          opacity: interpolate(titleSpring, [0, 0.5], [0, 1], {
            extrapolateRight: "clamp",
          }),
          transform: `translateY(${interpolate(titleSpring, [0, 1], [30, 0])}px)`,
        }}
      >
        <div
          style={{
            fontSize: 48,
            fontWeight: 900,
            color: "#0B132B",
            marginBottom: 12,
          }}
        >
          Voici Ryze
        </div>
        <div
          style={{
            fontSize: 24,
            fontWeight: 500,
            color: "#64748B",
          }}
        >
          Ton planificateur intelligent
        </div>
      </div>

      {/* Phone */}
      <div
        style={{
          position: "absolute",
          top: phoneY,
          left: "50%",
          transform: `translateX(-50%) scale(${phoneScale})`,
          opacity: phoneOpacity,
        }}
      >
        <PhoneMockup
          screenshot="planner_01.png"
          scale={1}
          shadowIntensity={1.2}
        />
      </div>

      {/* Badge */}
      <div
        style={{
          position: "absolute",
          bottom: 180,
          left: "50%",
          transform: "translateX(-50%)",
        }}
      >
        <GradientBadge
          text="Planificateur IA"
          delay={50}
        />
      </div>
    </AbsoluteFill>
  );
};
