import type { Metadata } from "next";
import { Inter, Oswald, Orbitron } from "next/font/google";
import "./globals.css";

const inter = Inter({
  subsets: ["latin"],
  variable: "--font-body",
});

const oswald = Oswald({
  subsets: ["latin"],
  weight: ["500", "600", "700"],
  variable: "--font-brutal",
});

const orbitron = Orbitron({
  subsets: ["latin"],
  weight: ["400", "500", "600", "700", "800", "900"],
  variable: "--font-mono",
});

export const metadata: Metadata = {
  title: "USTAD AI — Discipline as a Service",
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
    title: "USTAD AI — Discipline as a Service",
    description: "28 days. AI tracks every squat. Deposit collateral. No excuses.",
    type: "website",
  },
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en" className={`${inter.variable} ${oswald.variable} ${orbitron.variable}`} suppressHydrationWarning>
      <body className="scanlines" suppressHydrationWarning>{children}</body>
    </html>
  );
}
