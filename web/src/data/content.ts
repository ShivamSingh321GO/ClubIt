import type { ComponentType, SVGProps } from "react";
import {
  CalendarIcon,
  ShieldCheckIcon,
  QrCodeIcon,
  FormIcon,
  MegaphoneIcon,
  ChatIcon,
  TasksIcon,
  TrophyIcon,
  HierarchyIcon,
} from "@/components/Icons";

export type IconType = ComponentType<SVGProps<SVGSVGElement>>;

export interface Feature {
  icon: IconType;
  title: string;
  description: string;
}

export const features: Feature[] = [
  {
    icon: HierarchyIcon,
    title: "Configurable Org Hierarchy",
    description:
      "Model your institution the way it actually works — departments, chapters, or committees — with custom lead titles at every level.",
  },
  {
    icon: ShieldCheckIcon,
    title: "Multi-Stage Approvals",
    description:
      "Route events and budgets through Faculty, Admins, Leads, and Sub-Leads automatically — no chasing signatures.",
  },
  {
    icon: CalendarIcon,
    title: "Event Management",
    description:
      "Plan, edit, and publish events with venues, budgets, and resources attached — all in one workflow.",
  },
  {
    icon: QrCodeIcon,
    title: "QR Attendance",
    description:
      "Generate and scan QR codes to check attendees in within seconds, with attendance tracked in real time.",
  },
  {
    icon: FormIcon,
    title: "Smart Registration",
    description:
      "Build dynamic solo or team registration forms tailored to each event, no two the same.",
  },
  {
    icon: MegaphoneIcon,
    title: "Announcements",
    description:
      "Reach the right audience with a tap — organization-wide, group-only, or everyone at once.",
  },
  {
    icon: ChatIcon,
    title: "In-App Chat",
    description:
      "Keep every conversation organized and event-specific, so nothing important gets lost across groups.",
  },
  {
    icon: TasksIcon,
    title: "Task Delegation",
    description:
      "Assign, delegate, and track tasks across every group in your organization so everyone knows what they own.",
  },
  {
    icon: TrophyIcon,
    title: "Achievements",
    description:
      "Track and celebrate wins across every organization and member, building a record worth showing off.",
  },
];

export interface Role {
  name: string;
  description: string;
}

export const roles: Role[] = [
  {
    name: "Faculty",
    description: "Institution-wide oversight and final sign-off across every organization.",
  },
  {
    name: "Organization Admin",
    description: "Configure your organization's hierarchy, permissions, and settings.",
  },
  {
    name: "President / VP",
    description: "Approve events and budgets, and represent the organization at the top level.",
  },
  {
    name: "Group Lead / Sub-Lead",
    description: "Run a department, chapter, or committee — events, members, and tasks.",
  },
  {
    name: "Member",
    description: "Join events, register, chat, and build up achievements.",
  },
  {
    name: "Guest",
    description: "Explore public events across organizations before joining one.",
  },
];

export interface Step {
  title: string;
  description: string;
}

export const steps: Step[] = [
  {
    title: "Create",
    description: "Draft an event, announcement, or task in minutes.",
  },
  {
    title: "Approve",
    description: "It's automatically routed to the right people, in the right order.",
  },
  {
    title: "Engage",
    description: "Members register, chat, and check in with QR attendance.",
  },
  {
    title: "Track",
    description: "Follow progress with activity logs and achievements.",
  },
];

export const navLinks = [
  { label: "Features", href: "#features" },
  { label: "Roles", href: "#roles" },
  { label: "How it works", href: "#how-it-works" },
  { label: "Contact", href: "#contact" },
];

export const socialLinks = [
  { label: "Instagram", icon: "/images/instagram.png", href: "#" },
  { label: "LinkedIn", icon: "/images/linkedin.png", href: "#" },
  { label: "Discord", icon: "/images/discord.png", href: "#" },
  { label: "WhatsApp", icon: "/images/whatsapp.png", href: "#" },
  { label: "Facebook", icon: "/images/facebook.png", href: "#" },
];

export const contactEmail = "hello@loopapp.com";
