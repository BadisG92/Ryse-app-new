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
import { AnimatedWords } from "../components/AnimatedText";

const { fontFamily } = loadFont("normal", {
  weights: ["400", "500", "600", "700", "800", "900"],
  subsets: ["latin"],
});

export const FinalCTA: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Fade in
  const fadeIn = interpolate(frame, [0, 30], [0, 1], {
    extrapolateRight: "clamp",
  });

  // Logo entrance
  const logoSpring = spring({
    frame,
    fps,
    config: {
      damping: 14,
      stiffness: 120,
      mass: 0.8,
    },
  });

  const logoScale = interpolate(logoSpring, [0, 1], [0.5, 1]);
  const logoOpacity = interpolate(logoSpring, [0, 0.4], [0, 1], {
    extrapolateRight: "clamp",
  });

  // Subtle logo pulse
  const logoPulse = interpolate(
    Math.sin((frame - 40) / 25),
    [-1, 1],
    [1, 1.03]
  );

  // CTA button entrance
  const buttonSpring = spring({
    frame: frame - 60,
    fps,
    config: {
      damping: 12,
      stiffness: 150,
      mass: 0.6,
    },
  });

  const buttonScale = interpolate(buttonSpring, [0, 1], [0.8, 1]);
  const buttonOpacity = interpolate(buttonSpring, [0, 0.3], [0, 1], {
    extrapolateRight: "clamp",
  });

  // Button shine effect
  const shineX = interpolate(frame, [80, 180], [-200, 400], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  // Subtitle
  const subtitleOpacity = interpolate(frame, [100, 130], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  // Blue particles - more dynamic
  const particles = Array.from({ length: 25 }, (_, i) => ({
    x: 540 + Math.cos(i * 0.25) * (280 + (i % 5) * 100),
    y: 960 + Math.sin(i * 0.25) * (220 + (i % 4) * 70),
    size: 5 + (i % 4) * 4,
    speed: 0.5 + (i % 3) * 0.3,
    delay: i * 4,
  }));

  // Animated concentric rings
  const rings = Array.from({ length: 4 }, (_, i) => ({
    delay: 20 + i * 30,
    maxSize: 300 + i * 150,
  }));

  // Floating geometric accents
  const geometricAccents = Array.from({ length: 10 }, (_, i) => ({
    x: 80 + (i % 5) * 220,
    y: 200 + Math.floor(i / 5) * 1200,
    size: 15 + (i % 3) * 10,
    rotation: i * 36,
    delay: 40 + i * 12,
    type: i % 3, // 0: circle, 1: square, 2: diamond
  }));

  // Energy waves from button
  const energyWaves = Array.from({ length: 3 }, (_, i) => ({
    delay: 80 + i * 40,
  }));

  // Shooting stars / motion lines
  const motionLines = Array.from({ length: 6 }, (_, i) => ({
    startX: -100,
    startY: 400 + i * 200,
    angle: -15 + (i % 3) * 10,
    length: 150 + (i % 2) * 100,
    delay: 100 + i * 25,
    speed: 15 + (i % 3) * 5,
  }));

  return (
    <AbsoluteFill
      style={{
        background: "#FFFFFF",
        fontFamily,
        opacity: fadeIn,
      }}
    >
      {/* Subtle radial gradient */}
      <div
        style={{
          position: "absolute",
          inset: 0,
          background: `
            radial-gradient(ellipse at 50% 40%, rgba(11,19,43,0.04) 0%, transparent 50%),
            radial-gradient(ellipse at 30% 70%, rgba(28,41,81,0.03) 0%, transparent 40%),
            radial-gradient(ellipse at 70% 60%, rgba(11,19,43,0.02) 0%, transparent 40%)
          `,
        }}
      />

      {/* Animated concentric rings */}
      {rings.map((ring, i) => {
        const ringProgress = interpolate(
          frame - ring.delay,
          [0, 80],
          [0, 1],
          { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
        );
        const ringScale = interpolate(ringProgress, [0, 1], [0.3, 1.5]);
        const ringOpacity = interpolate(ringProgress, [0, 0.2, 0.8, 1], [0, 0.12, 0.08, 0]);

        if (frame < ring.delay) return null;

        return (
          <div
            key={`ring-${i}`}
            style={{
              position: "absolute",
              top: "50%",
              left: "50%",
              transform: `translate(-50%, -50%) scale(${ringScale})`,
              width: ring.maxSize,
              height: ring.maxSize,
              borderRadius: "50%",
              border: "2px solid #0B132B",
              opacity: ringOpacity,
            }}
          />
        );
      })}

      {/* Floating geometric accents */}
      {geometricAccents.map((accent, i) => {
        const accentProgress = frame - accent.delay;
        const floatY = Math.sin(accentProgress / 30) * 20;
        const floatX = Math.cos(accentProgress / 40) * 10;
        const rotation = accent.rotation + accentProgress * 0.5;
        const accentOpacity = interpolate(
          accentProgress,
          [0, 25, 400, 450],
          [0, 0.2, 0.2, 0],
          { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
        );

        if (frame < accent.delay) return null;

        return (
          <div
            key={`accent-${i}`}
            style={{
              position: "absolute",
              left: accent.x + floatX,
              top: accent.y + floatY,
              width: accent.size,
              height: accent.size,
              background: accent.type === 0 ? "#0B132B" : "transparent",
              border: accent.type !== 0 ? "2px solid #0B132B" : "none",
              borderRadius: accent.type === 0 ? "50%" : accent.type === 2 ? "2px" : "4px",
              opacity: accentOpacity,
              transform: `rotate(${rotation}deg)`,
            }}
          />
        );
      })}

      {/* Motion lines (shooting across) */}
      {motionLines.map((line, i) => {
        const lineProgress = (frame - line.delay) * line.speed / 60;
        if (frame < line.delay || lineProgress > 2) return null;

        const currentX = line.startX + lineProgress * 1400;
        const currentY = line.startY + lineProgress * Math.tan(line.angle * Math.PI / 180) * 1400;
        const lineOpacity = interpolate(
          lineProgress,
          [0, 0.1, 0.8, 1.2],
          [0, 0.5, 0.3, 0],
          { extrapolateRight: "clamp" }
        );

        return (
          <div
            key={`motion-${i}`}
            style={{
              position: "absolute",
              left: currentX,
              top: currentY,
              width: line.length,
              height: 3,
              background: `linear-gradient(90deg, transparent, ${i % 2 === 0 ? "#0B132B" : "#1C2951"}, transparent)`,
              opacity: lineOpacity,
              transform: `rotate(${line.angle}deg)`,
              borderRadius: 2,
            }}
          />
        );
      })}

      {/* Energy waves from CTA */}
      {energyWaves.map((wave, i) => {
        const waveProgress = ((frame - wave.delay) % 60) / 60;
        if (frame < wave.delay) return null;

        const waveScale = interpolate(waveProgress, [0, 1], [1, 2]);
        const waveOpacity = interpolate(waveProgress, [0, 0.3, 1], [0.3, 0.15, 0]);

        return (
          <div
            key={`wave-${i}`}
            style={{
              position: "absolute",
              top: "50%",
              left: "50%",
              transform: `translate(-50%, calc(-50% + 60px)) scale(${waveScale})`,
              width: 200,
              height: 60,
              borderRadius: 30,
              border: "2px solid #0B132B",
              opacity: waveOpacity,
            }}
          />
        );
      })}

      {/* Panda welcome arms - bottom left */}
      <div
        style={{
          position: "absolute",
          bottom: -40,
          left: -60,
          opacity: interpolate(frame, [80, 110], [0, 1], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          }),
          transform: `translateX(${interpolate(frame, [80, 110], [-50, 0], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          })}px) rotate(-5deg)`,
        }}
      >
        <Img
          src={staticFile("coach_ryze_welcome_arms.png")}
          style={{
            width: 480,
            height: 480,
            objectFit: "contain",
          }}
        />
      </div>

      {/* Panda nutrition - bottom right */}
      <div
        style={{
          position: "absolute",
          bottom: -20,
          right: -60,
          opacity: interpolate(frame, [90, 120], [0, 1], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          }),
          transform: `translateX(${interpolate(frame, [90, 120], [50, 0], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          })}px) rotate(5deg)`,
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

      {/* Floating particles - enhanced */}
      {particles.map((p, i) => {
        const particleY = p.y - (frame - p.delay) * p.speed;
        const wobbleX = Math.sin((frame + i * 12) / 30) * 25;
        const wobbleScale = 1 + Math.sin((frame + i * 8) / 20) * 0.15;
        const particleOpacity = interpolate(
          frame - p.delay,
          [0, 25, 400, 480],
          [0, 0.45, 0.35, 0],
          { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
        );

        if (frame < p.delay) return null;

        return (
          <div
            key={i}
            style={{
              position: "absolute",
              left: p.x + wobbleX,
              top: particleY,
              width: p.size,
              height: p.size,
              borderRadius: i % 3 === 0 ? "50%" : "3px",
              background: i % 3 === 0 ? "#0B132B" : i % 3 === 1 ? "#1C2951" : "transparent",
              border: i % 3 === 2 ? "2px solid #0B132B" : "none",
              opacity: particleOpacity,
              transform: `scale(${wobbleScale}) rotate(${frame * 0.5 + i * 45}deg)`,
              boxShadow: i % 4 === 0 ? "0 0 8px rgba(11,19,43,0.2)" : "none",
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
          transform: "translate(-50%, -50%)",
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
        }}
      >
        {/* Logo */}
        <div
          style={{
            marginBottom: 50,
            transform: `scale(${logoScale * (frame > 40 ? logoPulse : 1)})`,
            opacity: logoOpacity,
            position: "relative",
          }}
        >
          {/* Glow */}
          <div
            style={{
              position: "absolute",
              inset: -30,
              background: "radial-gradient(circle, rgba(11,19,43,0.15) 0%, transparent 70%)",
              filter: "blur(20px)",
              borderRadius: "50%",
            }}
          />
          <Img
            src={staticFile("app_icon.png")}
            style={{
              width: 140,
              height: 140,
              borderRadius: 32,
              boxShadow: `
                0 25px 60px rgba(11, 19, 43, 0.2),
                0 10px 25px rgba(11, 19, 43, 0.15)
              `,
            }}
          />
        </div>

        {/* Main headline */}
        <AnimatedWords
          text="Transforme ta nutrition"
          fontSize={48}
          fontWeight={900}
          color="#0B132B"
          delay={25}
          wordDelay={6}
          style={{ marginBottom: 60 }}
        />

        {/* CTA Button */}
        <div
          style={{
            opacity: buttonOpacity,
            transform: `scale(${buttonScale})`,
            position: "relative",
            overflow: "hidden",
          }}
        >
          <div
            style={{
              background: "linear-gradient(135deg, #0B132B 0%, #1C2951 100%)",
              borderRadius: 18,
              padding: "22px 56px",
              display: "flex",
              alignItems: "center",
              gap: 14,
              boxShadow: `
                0 20px 50px rgba(11, 19, 43, 0.3),
                0 8px 20px rgba(11, 19, 43, 0.2)
              `,
              position: "relative",
              overflow: "hidden",
            }}
          >
            {/* Shine effect */}
            <div
              style={{
                position: "absolute",
                top: 0,
                left: shineX,
                width: 100,
                height: "100%",
                background: "linear-gradient(90deg, transparent, rgba(255,255,255,0.15), transparent)",
                transform: "skewX(-20deg)",
              }}
            />

            <span
              style={{
                fontSize: 22,
                fontWeight: 700,
                color: "#FFFFFF",
                letterSpacing: 0.5,
              }}
            >
              Télécharger Ryze
            </span>
            <svg
              width="22"
              height="22"
              viewBox="0 0 24 24"
              fill="none"
              stroke="#FFFFFF"
              strokeWidth="2.5"
              strokeLinecap="round"
              strokeLinejoin="round"
            >
              <path d="M5 12h14M12 5l7 7-7 7" />
            </svg>
          </div>
        </div>

        {/* Subtitle */}
        <div
          style={{
            marginTop: 30,
            opacity: subtitleOpacity,
            transform: `translateY(${interpolate(subtitleOpacity, [0, 1], [15, 0])}px)`,
          }}
        >
          <span
            style={{
              fontSize: 20,
              fontWeight: 500,
              color: "#64748B",
            }}
          >
            7 jours d'essai gratuit
          </span>
        </div>
      </div>

      {/* App Store indicator */}
      <div
        style={{
          position: "absolute",
          bottom: 140,
          left: "50%",
          transform: "translateX(-50%)",
          opacity: interpolate(frame, [140, 170], [0, 1], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          }),
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          gap: 8,
        }}
      >
        <span
          style={{
            fontSize: 13,
            fontWeight: 600,
            color: "#94A3B8",
            letterSpacing: 2,
            textTransform: "uppercase",
          }}
        >
          Disponible sur
        </span>
        <span
          style={{
            fontSize: 18,
            fontWeight: 700,
            color: "#0B132B",
          }}
        >
          App Store
        </span>
      </div>

      {/* RYZE brand */}
      <div
        style={{
          position: "absolute",
          bottom: 60,
          left: "50%",
          transform: "translateX(-50%)",
          opacity: interpolate(frame, [160, 190], [0, 0.4], {
            extrapolateLeft: "clamp",
            extrapolateRight: "clamp",
          }),
        }}
      >
        <span
          style={{
            fontSize: 22,
            fontWeight: 800,
            color: "#0B132B",
            letterSpacing: 8,
          }}
        >
          RYZE
        </span>
      </div>
    </AbsoluteFill>
  );
};
