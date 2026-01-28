import React from "react";
import { Img, staticFile, useCurrentFrame, interpolate } from "remotion";

interface PhoneMockupProps {
  screenshot: string;
  scale?: number;
  style?: React.CSSProperties;
  showDynamicIsland?: boolean;
  shadowIntensity?: number;
}

export const PhoneMockup: React.FC<PhoneMockupProps> = ({
  screenshot,
  scale = 1,
  style = {},
  showDynamicIsland = true,
  shadowIntensity = 1,
}) => {
  const frame = useCurrentFrame();

  // Subtle floating animation
  const floatY = Math.sin(frame / 50) * 3;

  return (
    <div
      style={{
        position: "relative",
        transform: `scale(${scale}) translateY(${floatY}px)`,
        ...style,
      }}
    >
      {/* Phone shadow - multi-layer for realism */}
      <div
        style={{
          position: "absolute",
          bottom: -60,
          left: "50%",
          transform: "translateX(-50%)",
          width: 280,
          height: 40,
          background: `radial-gradient(ellipse, rgba(11,19,43,${0.25 * shadowIntensity}) 0%, transparent 70%)`,
          filter: "blur(20px)",
        }}
      />
      <div
        style={{
          position: "absolute",
          bottom: -30,
          left: "50%",
          transform: "translateX(-50%)",
          width: 200,
          height: 20,
          background: `radial-gradient(ellipse, rgba(11,19,43,${0.15 * shadowIntensity}) 0%, transparent 70%)`,
          filter: "blur(10px)",
        }}
      />

      {/* Phone frame - premium black with subtle gradient */}
      <div
        style={{
          width: 380,
          height: 820,
          background: "linear-gradient(145deg, #2a2a2a 0%, #1a1a1a 50%, #0f0f0f 100%)",
          borderRadius: 55,
          padding: 10,
          boxShadow: `
            0 50px 100px rgba(11,19,43,${0.3 * shadowIntensity}),
            0 20px 40px rgba(11,19,43,${0.2 * shadowIntensity}),
            inset 0 1px 0 rgba(255,255,255,0.1),
            inset 0 -1px 0 rgba(0,0,0,0.3)
          `,
          position: "relative",
        }}
      >
        {/* Side buttons (subtle) */}
        <div
          style={{
            position: "absolute",
            right: -2,
            top: 180,
            width: 4,
            height: 40,
            background: "linear-gradient(180deg, #3a3a3a, #2a2a2a)",
            borderRadius: "0 2px 2px 0",
          }}
        />
        <div
          style={{
            position: "absolute",
            left: -2,
            top: 140,
            width: 4,
            height: 30,
            background: "linear-gradient(180deg, #3a3a3a, #2a2a2a)",
            borderRadius: "2px 0 0 2px",
          }}
        />
        <div
          style={{
            position: "absolute",
            left: -2,
            top: 200,
            width: 4,
            height: 60,
            background: "linear-gradient(180deg, #3a3a3a, #2a2a2a)",
            borderRadius: "2px 0 0 2px",
          }}
        />
        <div
          style={{
            position: "absolute",
            left: -2,
            top: 280,
            width: 4,
            height: 60,
            background: "linear-gradient(180deg, #3a3a3a, #2a2a2a)",
            borderRadius: "2px 0 0 2px",
          }}
        />

        {/* Screen container with inner shadow */}
        <div
          style={{
            width: "100%",
            height: "100%",
            borderRadius: 46,
            overflow: "hidden",
            background: "#FFFFFF",
            position: "relative",
            boxShadow: "inset 0 0 0 1px rgba(0,0,0,0.1)",
          }}
        >
          {/* Screenshot */}
          <Img
            src={staticFile(screenshot)}
            style={{
              width: "100%",
              height: "100%",
              objectFit: "cover",
            }}
          />

          {/* Screen glare/reflection */}
          <div
            style={{
              position: "absolute",
              inset: 0,
              background: "linear-gradient(135deg, rgba(255,255,255,0.1) 0%, transparent 50%, transparent 100%)",
              pointerEvents: "none",
            }}
          />
        </div>

        {/* Dynamic Island */}
        {showDynamicIsland && (
          <div
            style={{
              position: "absolute",
              top: 20,
              left: "50%",
              transform: "translateX(-50%)",
              width: 126,
              height: 37,
              background: "#000000",
              borderRadius: 20,
              zIndex: 10,
              boxShadow: "0 2px 8px rgba(0,0,0,0.3)",
            }}
          >
            {/* Camera lens */}
            <div
              style={{
                position: "absolute",
                right: 20,
                top: "50%",
                transform: "translateY(-50%)",
                width: 12,
                height: 12,
                borderRadius: "50%",
                background: "radial-gradient(circle at 30% 30%, #3a3a3a, #1a1a1a)",
                boxShadow: "inset 0 1px 2px rgba(255,255,255,0.1)",
              }}
            />
          </div>
        )}
      </div>
    </div>
  );
};

// Phone with transition between multiple screenshots
interface PhoneWithTransitionProps {
  screenshots: string[];
  currentIndex: number;
  transitionProgress: number;
  scale?: number;
  style?: React.CSSProperties;
}

export const PhoneWithTransition: React.FC<PhoneWithTransitionProps> = ({
  screenshots,
  currentIndex,
  transitionProgress,
  scale = 1,
  style = {},
}) => {
  const frame = useCurrentFrame();
  const floatY = Math.sin(frame / 50) * 3;

  const currentScreenshot = screenshots[currentIndex] || screenshots[0];
  const nextScreenshot = screenshots[Math.min(currentIndex + 1, screenshots.length - 1)];

  return (
    <div
      style={{
        position: "relative",
        transform: `scale(${scale}) translateY(${floatY}px)`,
        ...style,
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
          background: "radial-gradient(ellipse, rgba(11,19,43,0.25) 0%, transparent 70%)",
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
            0 50px 100px rgba(11,19,43,0.3),
            0 20px 40px rgba(11,19,43,0.2),
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
            background: "#FFFFFF",
            position: "relative",
          }}
        >
          {/* Current screenshot */}
          <Img
            src={staticFile(currentScreenshot)}
            style={{
              position: "absolute",
              width: "100%",
              height: "100%",
              objectFit: "cover",
              opacity: 1 - transitionProgress,
            }}
          />
          {/* Next screenshot */}
          {transitionProgress > 0 && (
            <Img
              src={staticFile(nextScreenshot)}
              style={{
                position: "absolute",
                width: "100%",
                height: "100%",
                objectFit: "cover",
                opacity: transitionProgress,
              }}
            />
          )}
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
            background: "#000000",
            borderRadius: 20,
            zIndex: 10,
          }}
        />
      </div>
    </div>
  );
};
