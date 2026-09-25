import Reveal from "./Reveal";
import { steps } from "@/data/content";

export default function HowItWorks() {
  return (
    <section id="how-it-works" className="px-6 py-24 sm:py-32">
      <div className="mx-auto max-w-6xl">
        <Reveal className="mx-auto max-w-2xl text-center">
          <h2 className="text-3xl font-semibold tracking-tight sm:text-4xl">
            From idea to attendance, in four steps
          </h2>
          <p className="mt-4 text-base leading-7 text-muted sm:text-lg">
            No spreadsheets, no group-chat chaos — just a clear path from
            planning to follow-through.
          </p>
        </Reveal>

        <div className="relative mt-16 grid grid-cols-1 gap-8 sm:grid-cols-2 lg:grid-cols-4">
          <div
            aria-hidden
            className="absolute top-6 left-0 right-0 hidden h-px bg-border lg:block"
          />
          {steps.map((step, i) => (
            <Reveal key={step.title} delay={i * 80}>
              <div className="relative flex flex-col items-start">
                <div className="relative z-10 flex h-12 w-12 items-center justify-center rounded-full bg-primary text-base font-semibold text-primary-foreground">
                  {i + 1}
                </div>
                <h3 className="mt-5 text-lg font-semibold tracking-tight">
                  {step.title}
                </h3>
                <p className="mt-2 text-sm leading-6 text-muted">
                  {step.description}
                </p>
              </div>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  );
}
