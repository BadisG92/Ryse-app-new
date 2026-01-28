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
  weights: ["400", "500", "600"],
  subsets: ["latin"],
});

// Chat bubble component
const ChatBubble: React.FC<{
  text: string;
  isUser: boolean;
  delay: number;
  showAvatar?: boolean;
}> = ({ text, isUser, delay, showAvatar = false }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const bubbleSpring = spring({
    frame: frame - delay,
    fps,
    config: { damping: 15, stiffness: 120 },
  });

  const opacity = interpolate(bubbleSpring, [0, 1], [0, 1], {
    extrapolateLeft: "clamp",
  });
  const scale = interpolate(bubbleSpring, [0, 1], [0.8, 1], {
    extrapolateLeft: "clamp",
  });
  const y = interpolate(bubbleSpring, [0, 1], [15, 0], {
    extrapolateLeft: "clamp",
  });

  if (frame < delay) return null;

  return (
    <div
      style={{
        display: "flex",
        justifyContent: isUser ? "flex-end" : "flex-start",
        alignItems: "flex-end",
        gap: 8,
        marginBottom: 12,
        opacity,
        transform: `translateY(${y}px) scale(${scale})`,
        paddingLeft: isUser ? 40 : 0,
        paddingRight: isUser ? 0 : 40,
      }}
    >
      {!isUser && showAvatar && (
        <Img
          src={staticFile("ryze_nutrition.png")}
          style={{
            width: 28,
            height: 28,
            borderRadius: 6,
            objectFit: "cover",
          }}
        />
      )}
      {!isUser && !showAvatar && <div style={{ width: 28 }} />}

      <div
        style={{
          maxWidth: 240,
          padding: "10px 14px",
          borderRadius: 16,
          borderBottomLeftRadius: isUser ? 16 : 4,
          borderBottomRightRadius: isUser ? 4 : 16,
          background: isUser ? "#0B132B" : "#F1F5F9",
          color: isUser ? "#FFFFFF" : "#0B132B",
          fontSize: 14,
          fontWeight: 400,
          lineHeight: 1.4,
        }}
      >
        {text}
      </div>
    </div>
  );
};

// Typing indicator
const TypingDots: React.FC<{ delay: number; duration: number }> = ({ delay, duration }) => {
  const frame = useCurrentFrame();

  if (frame < delay || frame > delay + duration) return null;

  const localFrame = frame - delay;
  // Use sin for smooth looping animation
  const dot1 = 0.3 + 0.7 * (0.5 + 0.5 * Math.sin(localFrame * 0.3));
  const dot2 = 0.3 + 0.7 * (0.5 + 0.5 * Math.sin(localFrame * 0.3 - 1));
  const dot3 = 0.3 + 0.7 * (0.5 + 0.5 * Math.sin(localFrame * 0.3 - 2));

  return (
    <div
      style={{
        display: "flex",
        alignItems: "flex-end",
        gap: 8,
        marginBottom: 12,
      }}
    >
      <Img
        src={staticFile("ryze_nutrition.png")}
        style={{
          width: 28,
          height: 28,
          borderRadius: 6,
          objectFit: "cover",
        }}
      />
      <div
        style={{
          padding: "12px 16px",
          borderRadius: 16,
          borderBottomLeftRadius: 4,
          background: "#F1F5F9",
          display: "flex",
          gap: 4,
        }}
      >
        {[dot1, dot2, dot3].map((o, i) => (
          <div
            key={i}
            style={{
              width: 8,
              height: 8,
              borderRadius: "50%",
              background: "#64748B",
              opacity: o,
            }}
          />
        ))}
      </div>
    </div>
  );
};

export const PhoneShowcase: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Phone entrance with premium feel
  const phoneEntrance = interpolate(frame, [0, 40], [0, 1], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
    easing: Easing.bezier(0.16, 1, 0.3, 1),
  });

  const phoneY = interpolate(phoneEntrance, [0, 1], [800, 0]);
  const phoneScale = interpolate(phoneEntrance, [0, 1], [0.9, 1]);
  const phoneOpacity = interpolate(phoneEntrance, [0, 0.3], [0, 1], {
    extrapolateRight: "clamp",
  });

  // Subtle phone float
  const floatY = Math.sin(frame / 40) * 8;

  // Fade out
  const fadeOut = interpolate(frame, [200, 220], [1, 0], {
    extrapolateLeft: "clamp",
    extrapolateRight: "clamp",
  });

  // Chat timeline
  const WELCOME = 30;
  const USER_1 = 60;
  const TYPING_1 = 85;
  const BOT_1 = 110;
  const USER_2 = 140;
  const TYPING_2 = 160;
  const BOT_2 = 180;

  return (
    <AbsoluteFill
      style={{
        background: "#FFFFFF",
        fontFamily,
        opacity: fadeOut,
      }}
    >
      {/* Subtle gradient background */}
      <div
        style={{
          position: "absolute",
          inset: 0,
          background: "radial-gradient(ellipse at 50% 30%, rgba(11,19,43,0.03) 0%, transparent 60%)",
        }}
      />

      {/* Title */}
      <div
        style={{
          position: "absolute",
          top: 100,
          left: 0,
          right: 0,
          textAlign: "center",
          opacity: interpolate(frame, [20, 40], [0, 1], {
            extrapolateRight: "clamp",
          }),
          transform: `translateY(${interpolate(frame, [20, 40], [20, 0], {
            extrapolateRight: "clamp",
          })}px)`,
        }}
      >
        <div
          style={{
            fontSize: 42,
            fontWeight: 700,
            color: "#0B132B",
            marginBottom: 8,
          }}
        >
          Parle à Ryze
        </div>
        <div
          style={{
            fontSize: 22,
            fontWeight: 400,
            color: "#64748B",
          }}
        >
          Il planifie ta semaine en secondes
        </div>
      </div>

      {/* iPhone mockup */}
      <div
        style={{
          position: "absolute",
          top: "50%",
          left: "50%",
          transform: `translate(-50%, -50%) translateY(${phoneY + floatY}px) scale(${phoneScale})`,
          opacity: phoneOpacity,
        }}
      >
        {/* Phone shadow */}
        <div
          style={{
            position: "absolute",
            bottom: -40,
            left: "50%",
            transform: "translateX(-50%)",
            width: 300,
            height: 40,
            background: "radial-gradient(ellipse, rgba(0,0,0,0.2) 0%, transparent 70%)",
            filter: "blur(10px)",
          }}
        />

        {/* Phone frame - iPhone 15 Pro style */}
        <div
          style={{
            width: 380,
            height: 780,
            background: "linear-gradient(145deg, #1a1a1a 0%, #2d2d2d 50%, #1a1a1a 100%)",
            borderRadius: 55,
            padding: 10,
            boxShadow: `
              0 50px 100px rgba(0,0,0,0.3),
              0 0 0 0.5px rgba(255,255,255,0.1),
              inset 0 0 0 1.5px rgba(255,255,255,0.05)
            `,
            position: "relative",
          }}
        >
          {/* Titanium edge effect */}
          <div
            style={{
              position: "absolute",
              inset: 2,
              borderRadius: 53,
              background: "linear-gradient(145deg, rgba(255,255,255,0.1) 0%, transparent 50%)",
              pointerEvents: "none",
            }}
          />

          {/* Screen */}
          <div
            style={{
              width: "100%",
              height: "100%",
              background: "#FFFFFF",
              borderRadius: 46,
              overflow: "hidden",
              position: "relative",
            }}
          >
            {/* Dynamic Island */}
            <div
              style={{
                position: "absolute",
                top: 12,
                left: "50%",
                transform: "translateX(-50%)",
                width: 120,
                height: 34,
                background: "#000000",
                borderRadius: 20,
                zIndex: 10,
              }}
            />

            {/* Status bar time */}
            <div
              style={{
                position: "absolute",
                top: 16,
                left: 30,
                fontSize: 15,
                fontWeight: 600,
                color: "#000",
                zIndex: 5,
              }}
            >
              9:41
            </div>

            {/* Chat header */}
            <div
              style={{
                position: "absolute",
                top: 54,
                left: 0,
                right: 0,
                padding: "12px 16px",
                background: "rgba(255,255,255,0.95)",
                backdropFilter: "blur(20px)",
                borderBottom: "0.5px solid rgba(0,0,0,0.1)",
                display: "flex",
                alignItems: "center",
                gap: 10,
                zIndex: 5,
              }}
            >
              <div
                style={{
                  width: 8,
                  height: 15,
                  borderLeft: "2.5px solid #0B132B",
                  borderBottom: "2.5px solid #0B132B",
                  transform: "rotate(45deg)",
                  marginRight: 8,
                }}
              />
              <Img
                src={staticFile("ryze_nutrition.png")}
                style={{
                  width: 36,
                  height: 36,
                  borderRadius: 10,
                  objectFit: "cover",
                }}
              />
              <div>
                <div style={{ fontSize: 16, fontWeight: 600, color: "#0B132B" }}>
                  Ryze
                </div>
                <div style={{ fontSize: 12, color: "#10B981" }}>
                  En ligne
                </div>
              </div>
            </div>

            {/* Chat messages */}
            <div
              style={{
                position: "absolute",
                top: 130,
                left: 0,
                right: 0,
                bottom: 80,
                padding: "12px",
                overflowY: "hidden",
              }}
            >
              <ChatBubble
                text="Salut ! Qu'est-ce que tu veux planifier cette semaine ?"
                isUser={false}
                delay={WELCOME}
                showAvatar={true}
              />

              <ChatBubble
                text="Je veux des repas sains pour perdre du poids"
                isUser={true}
                delay={USER_1}
              />

              <TypingDots delay={TYPING_1} duration={25} />

              <ChatBubble
                text="Parfait ! Je te prépare 5 jours de repas équilibrés, riches en protéines 💪"
                isUser={false}
                delay={BOT_1}
                showAvatar={true}
              />

              <ChatBubble
                text="Génial, valide !"
                isUser={true}
                delay={USER_2}
              />

              <TypingDots delay={TYPING_2} duration={20} />

              <ChatBubble
                text="C'est fait ! Ta semaine est planifiée ✅"
                isUser={false}
                delay={BOT_2}
                showAvatar={true}
              />
            </div>

            {/* Input bar */}
            <div
              style={{
                position: "absolute",
                bottom: 0,
                left: 0,
                right: 0,
                padding: "12px 16px 30px",
                background: "rgba(255,255,255,0.95)",
                backdropFilter: "blur(20px)",
                borderTop: "0.5px solid rgba(0,0,0,0.1)",
              }}
            >
              <div
                style={{
                  background: "#F1F5F9",
                  borderRadius: 20,
                  padding: "10px 16px",
                  fontSize: 15,
                  color: "#94A3B8",
                }}
              >
                Message...
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Success indicator */}
      {frame >= BOT_2 + 15 && (
        <div
          style={{
            position: "absolute",
            bottom: 150,
            left: "50%",
            transform: "translateX(-50%)",
            display: "flex",
            alignItems: "center",
            gap: 10,
            opacity: interpolate(frame - BOT_2 - 15, [0, 15], [0, 1], {
              extrapolateRight: "clamp",
            }),
          }}
        >
          <div
            style={{
              width: 28,
              height: 28,
              borderRadius: "50%",
              background: "#10B981",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              color: "#FFFFFF",
              fontSize: 16,
              fontWeight: 700,
            }}
          >
            ✓
          </div>
          <span
            style={{
              fontSize: 18,
              fontWeight: 500,
              color: "#10B981",
            }}
          >
            15 secondes chrono
          </span>
        </div>
      )}
    </AbsoluteFill>
  );
};
