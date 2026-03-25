import type { Metadata } from "next";
import { Rajdhani, Orbitron } from "next/font/google";
import "./globals.css";

const rajdhani = Rajdhani({
  subsets: ["latin"],
  weight: ["300", "400", "500", "600", "700"],
  variable: "--font-body",
});

const orbitron = Orbitron({
  subsets: ["latin"],
  weight: ["400", "500", "600", "700", "800", "900"],
  variable: "--font-mono",
});

export const metadata: Metadata = {
  title: "USTAD AI — Discipline as a Service | ₹149/mo",
  description:
    "Your body is soft. The Ustad will fix that. 28-day AI-enforced calisthenics protocol with real collateral. No gym required.",
  keywords: [
    "fitness app",
    "calisthenics",
    "AI fitness",
    "home workout",
    "discipline",
    "ustad ai",
    "kasrat",
  ],
  openGraph: {
    title: "USTAD AI — Your Body is Soft. We Are The Ransom Demand.",
    description: "₹149/mo. 28 days. AI tracks every squat. Deposit collateral. No excuses.",
    type: "website",
  },
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en" className={`${rajdhani.variable} ${orbitron.variable}`}>
      <body className="scanlines">{children}</body>
    </html>
  );
}
