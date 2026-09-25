import Reveal from "./Reveal";
import { roles } from "@/data/content";
import { UsersIcon } from "./Icons";

export default function Roles() {
  return (
    <section id="roles" className="px-6 py-24 sm:py-32">
      <div className="mx-auto max-w-6xl">
        <div className="grid grid-cols-1 gap-12 lg:grid-cols-[minmax(0,1fr)_minmax(0,1.4fr)] lg:items-center">
          <Reveal>
            <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-primary/10 text-primary">
              <UsersIcon className="h-6 w-6" />
            </div>
            <h2 className="mt-6 text-3xl font-semibold tracking-tight sm:text-4xl">
              Built for how organizations are actually structured
            </h2>
            <p className="mt-4 text-base leading-7 text-muted sm:text-lg">
              From institution admins to first-time members, everyone gets a
              view built for their role — with a hierarchy your organization
              can shape to match its own structure, and approvals flowing
              exactly where they need to.
            </p>
          </Reveal>

          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            {roles.map((role, i) => (
              <Reveal key={role.name} delay={i * 60}>
                <div className="h-full rounded-2xl border border-border bg-surface p-5 transition-colors duration-300 hover:border-primary/30">
                  <h3 className="text-sm font-semibold tracking-tight text-primary">
                    {role.name}
                  </h3>
                  <p className="mt-1.5 text-sm leading-6 text-muted">
                    {role.description}
                  </p>
                </div>
              </Reveal>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
