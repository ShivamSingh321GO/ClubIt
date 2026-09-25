import Image from "next/image";
import { ArrowRightIcon, SparkleIcon } from "./Icons";

export default function Hero() {
  return (
    <section
      id="top"
      className="relative overflow-hidden px-6 pt-20 pb-24 sm:pt-28 sm:pb-32"
    >
      <div
        aria-hidden
        className="pointer-events-none absolute inset-0 -z-10"
        style={{
          background:
            "radial-gradient(60% 50% at 50% -10%, color-mix(in srgb, var(--primary) 18%, transparent), transparent)",
        }}
      />

      <div className="mx-auto flex max-w-4xl flex-col items-center text-center">
        <div className="reveal in-view inline-flex items-center gap-2 rounded-full border border-border bg-surface px-4 py-1.5 text-xs font-medium text-muted">
          <SparkleIcon className="h-3.5 w-3.5 text-primary" />
          Built for institutions &amp; the organizations they run
        </div>

        <h1
          className="reveal in-view mt-6 text-4xl font-semibold tracking-tight text-balance sm:text-6xl"
          style={{ animationDelay: "80ms" }}
        >
          One platform to run{" "}
          <span className="text-primary">every organization</span> on
          campus.
        </h1>

        <p
          className="reveal in-view mt-6 max-w-2xl text-base leading-7 text-muted sm:text-lg"
          style={{ animationDelay: "160ms" }}
        >
          Loop gives institutions a single system to manage every
          organization beneath them — with configurable hierarchies,
          role-based approvals, events, attendance, chat, and tasks built in
          from day one.
        </p>

        <div
          className="reveal in-view mt-10 flex flex-col items-center gap-4 sm:flex-row"
          style={{ animationDelay: "240ms" }}
        >
          <a
            href="#contact"
            className="inline-flex w-full items-center justify-center gap-2 rounded-full bg-primary px-7 py-3.5 text-sm font-semibold text-primary-foreground transition-transform duration-200 hover:scale-[1.03] active:scale-[0.98] sm:w-auto"
          >
            Get in touch
            <ArrowRightIcon className="h-4 w-4" />
          </a>
          <a
            href="#features"
            className="inline-flex w-full items-center justify-center rounded-full border border-border bg-surface px-7 py-3.5 text-sm font-semibold text-foreground transition-colors duration-200 hover:border-primary/40 sm:w-auto"
          >
            Explore features
          </a>
        </div>
      </div>

      <div
        className="reveal in-view mx-auto mt-16 flex max-w-3xl items-center justify-center"
        style={{ animationDelay: "320ms" }}
      >
        <div className="relative flex h-40 w-40 items-center justify-center rounded-[2rem] bg-surface shadow-2xl shadow-primary/10 ring-1 ring-border sm:h-48 sm:w-48">
          <Image
            src="/images/logo.png"
            alt="Loop app icon"
            width={112}
            height={112}
            className="rounded-3xl"
            priority
          />
        </div>
      </div>
    </section>
  );
}
