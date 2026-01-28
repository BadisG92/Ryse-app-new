import { Composition } from "remotion";
import { PlannerPromo } from "./PlannerPromo";

export const RemotionRoot: React.FC = () => {
  return (
    <>
      <Composition
        id="PlannerPromo"
        component={PlannerPromo}
        durationInFrames={1800}
        fps={60}
        width={1080}
        height={1920}
        defaultProps={{}}
      />
    </>
  );
};
