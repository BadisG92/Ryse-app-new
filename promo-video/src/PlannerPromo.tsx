import { AbsoluteFill, Sequence } from "remotion";
import { LogoIntro } from "./scenes/LogoIntro";
import { HookScene } from "./scenes/HookScene";
import { PhoneReveal } from "./scenes/PhoneReveal";
import { ChatDemo } from "./scenes/ChatDemo";
import { CalendarResult } from "./scenes/CalendarResult";
import { FinalCTA } from "./scenes/FinalCTA";

/**
 * Ryze Planificateur Promo Video
 * 30 seconds @ 60fps = 1800 frames
 *
 * Timeline:
 * - Scene 1: LogoIntro (0-120) - 2s
 * - Scene 2: HookScene (100-400) - 5s (pain points stack up)
 * - Scene 3: PhoneReveal (380-560) - 3s
 * - Scene 4: ChatDemo (540-1020) - 8s
 * - Scene 5: CalendarResult (1000-1300) - 5s
 * - Scene 6: FinalCTA (1280-1800) - ~8.7s
 */
export const PlannerPromo: React.FC = () => {
  return (
    <AbsoluteFill style={{ background: "#FFFFFF" }}>
      {/* Scene 1: Logo Intro - 2s */}
      <Sequence from={0} durationInFrames={120} name="LogoIntro">
        <LogoIntro />
      </Sequence>

      {/* Scene 2: Hook/Problem - 5s (pain points appear stacked) */}
      <Sequence from={100} durationInFrames={300} name="HookScene">
        <HookScene />
      </Sequence>

      {/* Scene 3: Phone Reveal - 3s */}
      <Sequence from={380} durationInFrames={180} name="PhoneReveal">
        <PhoneReveal />
      </Sequence>

      {/* Scene 4: Chat Demo - 8s */}
      <Sequence from={540} durationInFrames={480} name="ChatDemo">
        <ChatDemo />
      </Sequence>

      {/* Scene 5: Calendar Result - 5s */}
      <Sequence from={1000} durationInFrames={300} name="CalendarResult">
        <CalendarResult />
      </Sequence>

      {/* Scene 6: Final CTA - ends at 1800 */}
      <Sequence from={1280} durationInFrames={520} name="FinalCTA">
        <FinalCTA />
      </Sequence>
    </AbsoluteFill>
  );
};
