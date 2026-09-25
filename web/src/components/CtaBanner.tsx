import Reveal from "./Reveal";
import { ArrowRightIcon } from "./Icons";
import { contactEmail } from "@/data/content";

export default function CtaBanner() {
  return (
    <section id="contact" className="px-6 py-24 sm:py-32">
      <Reveal className="mx-auto max-w-4xl">
        <div className="relative overflow-hidden rounded-3xl bg-primary px-8 py-16 text-center sm:px-16">
          <div
            aria-hidden
            className="pointer-events-none absolute inset-0"
            style={{
              background:
                "radial-gradient(60% 80% at 100% 0%, rgba(255,255,255,0.12), transparent)",
            }}
          />
          <h2 className="text-3xl font-semibold tracking-tight text-primary-foreground sm:text-4xl">
            Ready to bring your organization onto Loop?
          </h2>
          <p className="mx-auto mt-4 max-w-xl text-base leading-7 text-primary-foreground/85">
            Tell us about your institution, club, or society and we&apos;ll
            help you get set up — hierarchy, approvals, and attendance
            included.
          </p>
          <div className="mt-8 flex justify-center">
            <a
              href={`mailto:${contactEmail}`}
              className="inline-flex items-center gap-2 rounded-full bg-white px-7 py-3.5 text-sm font-semibold text-primary transition-transform duration-200 hover:scale-[1.03] active:scale-[0.98]"
            >
              Get in touch
              <ArrowRightIcon className="h-4 w-4" />
            </a>
          </div>
        </div>
      </Reveal>
    </section>
  );
}
