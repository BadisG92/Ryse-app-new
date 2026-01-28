import React from "react";
import { useCurrentFrame, useVideoConfig, spring, interpolate } from "remotion";

interface AnimatedTextProps {
  text: string;
  fontSize?: number;
  fontWeight?: number;
  color?: string;
  delay?: number;
  staggerDelay?: number;
  animationType?: "fadeUp" | "scale" | "slideLeft" | "slideRight";
  style?: React.CSSProperties;
}

export const AnimatedText: React.FC<AnimatedTextProps> = ({
  text,
  fontSize = 48,
  fontWeight = 700,
  color = "#0B132B",
  delay = 0,
  staggerDelay = 2,
  animationType = "fadeUp",
  style = {},
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const characters = text.split("");

  return (
    <div
      style={{
        display: "flex",
        flexWrap: "wrap",
        justifyContent: "center",
        ...style,
      }}
    >
      {characters.map((char, index) => {
        const charDelay = delay + index * staggerDelay;

        const charSpring = spring({
          frame: frame - charDelay,
          fps,
          config: {
            damping: 12,
            stiffness: 200,
            mass: 0.5,
          },
        });

        let transform = "";
        let opacity = charSpring;

        switch (animationType) {
          case "fadeUp":
            transform = `translateY(${interpolate(charSpring, [0, 1], [30, 0])}px)`;
            break;
          case "scale":
            transform = `scale(${interpolate(charSpring, [0, 1], [0.5, 1])})`;
            break;
          case "slideLeft":
            transform = `translateX(${interpolate(charSpring, [0, 1], [-50, 0])}px)`;
            break;
          case "slideRight":
            transform = `translateX(${interpolate(charSpring, [0, 1], [50, 0])}px)`;
            break;
        }

        return (
          <span
            key={index}
            style={{
              display: "inline-block",
              fontSize,
              fontWeight,
              color,
              opacity,
              transform,
              whiteSpace: char === " " ? "pre" : "normal",
              minWidth: char === " " ? "0.3em" : undefined,
            }}
          >
            {char}
          </span>
        );
      })}
    </div>
  );
};

// Word-by-word animation component
interface AnimatedWordsProps {
  text: string;
  fontSize?: number;
  fontWeight?: number;
  color?: string;
  delay?: number;
  wordDelay?: number;
  style?: React.CSSProperties;
}

export const AnimatedWords: React.FC<AnimatedWordsProps> = ({
  text,
  fontSize = 48,
  fontWeight = 700,
  color = "#0B132B",
  delay = 0,
  wordDelay = 8,
  style = {},
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const words = text.split(" ");

  return (
    <div
      style={{
        display: "flex",
        flexWrap: "wrap",
        justifyContent: "center",
        gap: "0.3em",
        ...style,
      }}
    >
      {words.map((word, index) => {
        const wDelay = delay + index * wordDelay;

        const wordSpring = spring({
          frame: frame - wDelay,
          fps,
          config: {
            damping: 14,
            stiffness: 180,
            mass: 0.6,
          },
        });

        const scale = interpolate(wordSpring, [0, 1], [0.8, 1]);
        const y = interpolate(wordSpring, [0, 1], [40, 0]);
        const opacity = interpolate(wordSpring, [0, 0.5], [0, 1], {
          extrapolateRight: "clamp",
        });

        return (
          <span
            key={index}
            style={{
              display: "inline-block",
              fontSize,
              fontWeight,
              color,
              opacity,
              transform: `translateY(${y}px) scale(${scale})`,
            }}
          >
            {word}
          </span>
        );
      })}
    </div>
  );
};
