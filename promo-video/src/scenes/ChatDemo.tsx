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

const { fontFamily } = loadFont("normal", {
  weights: ["400", "500", "600", "700", "800", "900"],
  subsets: ["latin"],
});

const textOverlays = [
  { text: "Parle à Ryze...", start: 20, end: 140 },
  { text: "Il comprend ta demande", start: 150, end: 280 },
  { text: "Et crée tes repas !", start: 300, end: 450 },
];

export const ChatDemo: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Fade transitions
  const fadeIn = interpolate(frame, [0, 20], [0, 1], {
    extrapolateRight: "clamp",
  });
  const fadeOut = interpolate(frame, [460, 480], [1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  // Screenshot transitions (smooth crossfades)
  // 0-160: planner_01 (initial chat)
  // 160-320: planner_02 (message sent)
  // 320-480: planner_03 (meals revealed)

  const screen1Opacity = interpolate(frame, [0, 20, 140, 170], [0, 1, 1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  const screen2Opacity = interpolate(frame, [150, 180, 290, 320], [0, 1, 1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  const screen3Opacity = interpolate(frame, [300, 330, 460, 480], [0, 1, 1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  // Progressive zoom
  const zoomProgress = interpolate(frame, [0, 480], [1, 1.25], {
    extrapolateRight: "clamp",
    easing: Easing.inOut(Easing.quad),
  });

  // Subtle pan following content
  const panY = interpolate(frame, [0, 160, 320, 480], [0, 30, 80, 120], {
    extrapolateRight: "clamp",
    easing: Easing.inOut(Easing.quad),
  });

  // Floating effect
  const floatY = Math.sin(frame / 50) * 4;

  // AI processing particles (burst when generating)
  const aiParticles = Array.from({ length: 25 }, (_, i) => ({
    angle: (i / 25) * Math.PI * 2,
    speed: 1.5 + (i % 4) * 0.5,
    size: 4 + (i % 3) * 3,
    delay: 160 + i * 2, // Start when "processing"
  }));

  // Connection lines (typing effect)
  const connectionLines = Array.from({ length: 5 }, (_, i) => ({
    startX: 200 + i * 40,
    startY: 400,
    endX: 540,
    endY: 800,
    delay: 30 + i * 15,
  }));

  // Orbiting dots around phone
  const orbitingDots = Array.from({ length: 8 }, (_, i) => ({
    angle: (i / 8) * Math.PI * 2,
    radius: 320 + (i % 2) * 40,
    size: 6 + (i % 3) * 2,
    speed: 0.015 + (i % 3) * 0.005,
  }));

  // Floating emoji/icons indicators
  const floatingIcons = [
    { x: 120, y: 300, delay: 50, emoji: "🍳" },
    { x: 960, y: 450, delay: 80, emoji: "🥗" },
    { x: 100, y: 1200, delay: 320, emoji: "✨" },
    { x: 950, y: 1100, delay: 350, emoji: "🎯" },
  ];

  return (
    <AbsoluteFill
      style={{
        background: "#FFFFFF",
        fontFamily,
        opacity: fadeIn * fadeOut,
        overflow: "hidden",
      }}
    >
      {/* Background gradient */}
      <div
        style={{
          position: "absolute",
          inset: 0,
          background: "radial-gradient(ellipse at 50% 60%, rgba(11,19,43,0.03) 0%, transparent 70%)",
        }}
      />

      {/* Orbiting dots around phone */}
      {orbitingDots.map((dot, i) => {
        const currentAngle = dot.angle + frame * dot.speed;
        const x = 540 + Math.cos(currentAngle) * dot.radius;
        const y = 900 + Math.sin(currentAngle) * dot.radius * 0.5;
        const dotOpacity = interpolate(frame, [20, 50, 440, 470], [0, 0.3, 0.3, 0], {
          extrapolateLeft: "clamp",
          extrapolateRight: "clamp",
        });

        return (
          <div
            key={`orbit-${i}`}
            style={{
              position: "absolute",
              left: x,
              top: y,
              width: dot.size,
              height: dot.size,
              borderRadius: "50%",
              background: i % 2 === 0 ? "#0B132B" : "#1C2951",
              opacity: dotOpacity,
              transform: "translate(-50%, -50%)",
            }}
          />
        );
      })}

      {/* AI processing burst particles */}
      {aiParticles.map((p, i) => {
        const burstProgress = (frame - p.delay) / 40;
        if (frame < p.delay || burstProgress > 1.5) return null;

        const distance = burstProgress * 150 * p.speed;
        const x = 540 + Math.cos(p.angle) * distance;
        const y = 750 + Math.sin(p.angle) * distance * 0.6;
        const particleOpacity = interpolate(
          burstProgress,
          [0, 0.2, 1, 1.5],
          [0, 0.6, 0.3, 0],
          { extrapolateRight: "clamp" }
        );

        return (
          <div
            key={`ai-${i}`}
            style={{
              position: "absolute",
              left: x,
              top: y,
              width: p.size,
              height: p.size,
              borderRadius: "50%",
              background: "linear-gradient(135deg, #0B132B, #1C2951)",
              opacity: particleOpacity,
              transform: "translate(-50%, -50%)",
              boxShadow: "0 0 8px rgba(11,19,43,0.3)",
            }}
          />
        );
      })}

      {/* Floating food icons */}
      {floatingIcons.map((icon, i) => {
        const iconProgress = frame - icon.delay;
        const floatYOffset = Math.sin(iconProgress / 25) * 15;
        const floatXOffset = Math.cos(iconProgress / 35) * 8;

        // Ensure strictly increasing values for interpolate
        const fadeOutStart = Math.max(31, 380 - icon.delay);
        const fadeOutEnd = fadeOutStart + 40;

        const iconOpacity = interpolate(
          iconProgress,
          [0, 30, fadeOutStart, fadeOutEnd],
          [0, 0.7, 0.7, 0],
          { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
        );
        const iconScale = interpolate(
          iconProgress,
          [0, 30],
          [0.5, 1],
          { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
        );

        if (frame < icon.delay) return null;

        return (
          <div
            key={`icon-${i}`}
            style={{
              position: "absolute",
              left: icon.x + floatXOffset,
              top: icon.y + floatYOffset,
              fontSize: 40,
              opacity: iconOpacity,
              transform: `scale(${iconScale})`,
              filter: "drop-shadow(0 4px 8px rgba(0,0,0,0.1))",
            }}
          >
            {icon.emoji}
          </div>
        );
      })}

      {/* Text overlays */}
      {textOverlays.map((overlay, index) => {
        const isActive = frame >= overlay.start && frame <= overlay.end;
        const entryProgress = interpolate(
          frame,
          [overlay.start, overlay.start + 20],
          [0, 1],
          { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
        );
        const exitProgress = interpolate(
          frame,
          [overlay.end - 15, overlay.end],
          [0, 1],
          { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
        );

        const opacity = entryProgress * (1 - exitProgress);
        const y = interpolate(entryProgress, [0, 1], [25, 0]);

        if (!isActive && frame > overlay.end) return null;
        if (frame < overlay.start - 5) return null;

        return (
          <div
            key={index}
            style={{
              position: "absolute",
              top: 100,
              left: 0,
              right: 0,
              textAlign: "center",
              zIndex: 20,
              opacity,
              transform: `translateY(${y}px)`,
            }}
          >
            <span
              style={{
                fontSize: 40,
                fontWeight: 700,
                color: "#0B132B",
              }}
            >
              {overlay.text}
            </span>
          </div>
        );
      })}

      {/* Phone container with zoom and pan */}
      <div
        style={{
          position: "absolute",
          top: "50%",
          left: "50%",
          transform: `translate(-50%, -50%) scale(${zoomProgress}) translateY(${-panY + floatY}px)`,
        }}
      >
        {/* Phone shadow */}
        <div
          style={{
            position: "absolute",
            bottom: -60,
            left: "50%",
            transform: "translateX(-50%)",
            width: 280,
            height: 40,
            background: "radial-gradient(ellipse, rgba(11,19,43,0.2) 0%, transparent 70%)",
            filter: "blur(20px)",
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
          {/* Screen */}
          <div
            style={{
              width: "100%",
              height: "100%",
              borderRadius: 46,
              overflow: "hidden",
              position: "relative",
              background: "#FFF",
            }}
          >
            {/* Screenshot 1 - Initial chat */}
            <Img
              src={staticFile("planner_01.png")}
              style={{
                position: "absolute",
                width: "100%",
                height: "100%",
                objectFit: "cover",
                opacity: screen1Opacity,
              }}
            />

            {/* Screenshot 2 - Message sent */}
            <Img
              src={staticFile("planner_02.png")}
              style={{
                position: "absolute",
                width: "100%",
                height: "100%",
                objectFit: "cover",
                opacity: screen2Opacity,
              }}
            />

            {/* Screenshot 3 - Meals revealed */}
            <Img
              src={staticFile("planner_03.png")}
              style={{
                position: "absolute",
                width: "100%",
                height: "100%",
                objectFit: "cover",
                opacity: screen3Opacity,
              }}
            />

            {/* Screen reflection */}
            <div
              style={{
                position: "absolute",
                inset: 0,
                background: "linear-gradient(135deg, rgba(255,255,255,0.08) 0%, transparent 50%)",
                pointerEvents: "none",
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

      {/* Progress dots */}
      <div
        style={{
          position: "absolute",
          bottom: 80,
          left: "50%",
          transform: "translateX(-50%)",
          display: "flex",
          gap: 12,
        }}
      >
        {[0, 1, 2].map((i) => {
          const isActive =
            (i === 0 && frame < 160) ||
            (i === 1 && frame >= 160 && frame < 320) ||
            (i === 2 && frame >= 320);

          return (
            <div
              key={i}
              style={{
                width: isActive ? 28 : 10,
                height: 10,
                borderRadius: 5,
                background: isActive
                  ? "linear-gradient(90deg, #0B132B, #1C2951)"
                  : "#E2E8F0",
                transition: "width 0.3s ease",
              }}
            />
          );
        })}
      </div>
    </AbsoluteFill>
  );
};
