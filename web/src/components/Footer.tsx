import Image from "next/image";
import { navLinks, socialLinks, contactEmail } from "@/data/content";

export default function Footer() {
  const year = new Date().getFullYear();

  return (
    <footer className="border-t border-border px-6 py-12">
      <div className="mx-auto flex max-w-6xl flex-col gap-10 sm:flex-row sm:items-start sm:justify-between">
        <div className="max-w-xs">
          <div className="flex items-center gap-2.5">
            <Image
              src="/images/logo.png"
              alt="Loop logo"
              width={28}
              height={28}
              className="rounded-lg"
            />
            <span className="text-base font-semibold tracking-tight">
              Loop
            </span>
          </div>
          <p className="mt-3 text-sm leading-6 text-muted">
            One place to run every organization on campus — hierarchy,
            events, approvals, attendance, chat, and tasks.
          </p>
        </div>

        <div className="flex flex-col gap-3">
          <span className="text-xs font-semibold tracking-wide text-muted uppercase">
            Site
          </span>
          {navLinks.map((link) => (
            <a
              key={link.href}
              href={link.href}
              className="text-sm text-muted transition-colors hover:text-foreground"
            >
              {link.label}
            </a>
          ))}
        </div>

        <div className="flex flex-col gap-3">
          <span className="text-xs font-semibold tracking-wide text-muted uppercase">
            Contact
          </span>
          <a
            href={`mailto:${contactEmail}`}
            className="text-sm text-muted transition-colors hover:text-foreground"
          >
            {contactEmail}
          </a>
          <div className="flex items-center gap-3 pt-1">
            {socialLinks.map((social) => (
              <a
                key={social.label}
                href={social.href}
                aria-label={social.label}
                className="flex h-9 w-9 items-center justify-center rounded-full border border-border bg-surface transition-colors hover:border-primary/40"
              >
                <Image
                  src={social.icon}
                  alt=""
                  width={16}
                  height={16}
                  className="opacity-80"
                />
              </a>
            ))}
          </div>
        </div>
      </div>

      <div className="mx-auto mt-10 max-w-6xl border-t border-border pt-6 text-xs text-muted">
        © {year} Loop. All rights reserved.
      </div>
    </footer>
  );
}
