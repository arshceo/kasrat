"use client";

import { useState } from "react";
import Link from "next/link";

const STATS = [
  { value: "28", label: "DAYS" },
  { value: "₹149", label: "/MONTH" },
  { value: "AI", label: "ENFORCED" },
  { value: "0", label: "EXCUSES" },
];

const FEATURES = [
  {
    icon: "📷",
    title: "AI POSE DETECTION",
    desc: "ML Kit watches every squat. No cheating. θ < 90° or it doesn't count.",
  },
  {
    icon: "💰",
    title: "COLLATERAL SYSTEM",
    desc: "Deposit ₹200. Complete 28 days = full refund. Fail = you fund someone else's transformation.",
  },
  {
    icon: "🤖",
    title: "GEMINI AI COACH",
    desc: "Personalized workout plans. Localized diet plans. Budget-friendly rations. In your language.",
  },
  {
    icon: "⏰",
    title: "6 AM ENFORCEMENT",
    desc: "Miss the alarm? The Ustad doesn't forgive. Your collateral is at risk every single day.",
  },
];

const TIERS = [
  { name: "ROOKIE", price: "₹149", period: "/mo", collateral: "₹200", features: ["Basic AI tracking", "28-day squat protocol", "Diet plan (budget)"] },
  { name: "GRUNT", price: "₹299", period: "/mo", collateral: "₹500", features: ["All Rookie features", "4 exercise types", "Premium diet plan", "Ustad voice coaching"], popular: true },
  { name: "COMMANDO", price: "₹499", period: "/mo", collateral: "₹1000", features: ["All Grunt features", "Custom plan by Gemini", "Priority support", "Exclusive challenges"] },
];

export default function LandingPage() {
  const [selectedTier, setSelectedTier] = useState(1);

  return (
    <main className="min-h-screen relative grid-bg">
      {/* Hero Section */}
      <section className="min-h-screen flex flex-col items-center justify-center px-6 text-center relative">
        {/* Red warning dots */}
        <div className="flex items-center gap-3 mb-8">
          <span className="w-2 h-2 rounded-full bg-neon-red shadow-[0_0_12px_rgba(255,0,0,0.6)]" />
          <span className="font-[var(--font-mono)] text-[10px] text-neon-red tracking-[6px] font-semibold">
            RESTRICTED PROTOCOL
          </span>
          <span className="w-2 h-2 rounded-full bg-neon-red shadow-[0_0_12px_rgba(255,0,0,0.6)]" />
        </div>

        {/* Main headline */}
        <h1 className="font-[var(--font-body)] text-5xl md:text-8xl font-bold text-text-primary leading-[0.95] tracking-wider mb-6">
          YOUR BODY
          <br />
          IS{" "}
          <span className="text-neon-red glow-text">SOFT</span>
        </h1>

        <p className="font-[var(--font-mono)] text-sm md:text-base text-text-secondary tracking-[4px] mb-2">
          WE ARE THE RANSOM DEMAND.
        </p>

        <div className="w-16 h-0.5 bg-neon-red my-8" />

        <p className="max-w-xl text-text-secondary text-lg leading-relaxed mb-10">
          For <span className="text-neon-red font-bold">₹149/mo</span>, the Ustad enforces discipline. 
          Deposit <span className="text-neon-red font-bold">₹200 collateral</span>. 
          Wake up at 6:00 AM. Do squats in front of the AI camera. 
          <span className="text-text-primary font-semibold"> Complete 28 days = full refund.</span>
        </p>

        {/* CTA */}
        <Link
          href="/checkout"
          className="inline-block bg-neon-red text-white font-[var(--font-mono)] text-sm tracking-[4px] font-bold px-12 py-5 pulse-glow hover:bg-red-700 transition-colors"
        >
          SUBMIT TO THE PROTOCOL
        </Link>

        {/* Stats bar */}
        <div className="grid grid-cols-4 gap-0 border border-neon-red/20 mt-16 w-full max-w-2xl">
          {STATS.map((stat, i) => (
            <div
              key={i}
              className={`py-4 px-2 text-center ${i < 3 ? "border-r border-neon-red/20" : ""}`}
            >
              <div className="font-[var(--font-body)] text-3xl font-bold text-neon-red">
                {stat.value}
              </div>
              <div className="font-[var(--font-mono)] text-[8px] text-text-muted tracking-[3px] mt-1">
                {stat.label}
              </div>
            </div>
          ))}
        </div>

        {/* Scroll indicator */}
        <div className="absolute bottom-8 animate-bounce">
          <div className="w-5 h-8 border-2 border-text-muted/30 rounded-full flex justify-center pt-1.5">
            <div className="w-1 h-2 bg-neon-red rounded-full" />
          </div>
        </div>
      </section>

      {/* Marquee */}
      <div className="border-y border-neon-red/20 py-3 overflow-hidden">
        <div className="marquee-track flex whitespace-nowrap">
          {Array(4)
            .fill(
              "NO GYM REQUIRED • AI ENFORCED • ₹149/MO • 28 DAYS • COLLATERAL SYSTEM • GEMINI POWERED • "
            )
            .map((text, i) => (
              <span
                key={i}
                className="font-[var(--font-mono)] text-xs text-neon-red/40 tracking-[6px] mx-4"
              >
                {text}
              </span>
            ))}
        </div>
      </div>

      {/* Features */}
      <section className="py-24 px-6">
        <div className="max-w-5xl mx-auto">
          <div className="flex items-center gap-3 mb-6">
            <div className="w-8 h-px bg-neon-red" />
            <span className="font-[var(--font-mono)] text-[10px] text-neon-red tracking-[4px]">
              // PROTOCOL FEATURES
            </span>
          </div>

          <h2 className="font-[var(--font-body)] text-4xl md:text-5xl font-bold text-text-primary mb-16 tracking-wider">
            HOW THE USTAD
            <br />
            <span className="text-neon-red">BREAKS</span> YOU
          </h2>

          <div className="grid md:grid-cols-2 gap-6">
            {FEATURES.map((f, i) => (
              <div
                key={i}
                className="border border-text-muted/10 bg-surface-glass p-8 hover:border-neon-red/30 transition-colors group"
              >
                <div className="text-3xl mb-4">{f.icon}</div>
                <h3 className="font-[var(--font-mono)] text-xs text-neon-red tracking-[3px] mb-3 font-semibold">
                  {f.title}
                </h3>
                <p className="text-text-secondary leading-relaxed">{f.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Pricing */}
      <section className="py-24 px-6 border-t border-neon-red/10">
        <div className="max-w-5xl mx-auto">
          <div className="flex items-center gap-3 mb-6">
            <div className="w-8 h-px bg-neon-red" />
            <span className="font-[var(--font-mono)] text-[10px] text-neon-red tracking-[4px]">
              // COLLATERAL TIERS
            </span>
          </div>

          <h2 className="font-[var(--font-body)] text-4xl font-bold text-text-primary mb-16 tracking-wider">
            CHOOSE YOUR <span className="text-neon-red">SUFFERING</span>
          </h2>

          <div className="grid md:grid-cols-3 gap-6">
            {TIERS.map((tier, i) => (
              <button
                key={i}
                onClick={() => setSelectedTier(i)}
                className={`text-left p-8 border transition-all relative ${
                  selectedTier === i
                    ? "border-neon-red bg-neon-red/5 glow-border"
                    : "border-text-muted/10 bg-surface-glass hover:border-text-muted/30"
                }`}
              >
                {tier.popular && (
                  <div className="absolute -top-3 left-1/2 -translate-x-1/2 bg-neon-red text-white font-[var(--font-mono)] text-[8px] tracking-[3px] px-4 py-1">
                    RECOMMENDED
                  </div>
                )}
                <div className="font-[var(--font-mono)] text-[10px] text-neon-red tracking-[4px] mb-4">{tier.name}</div>
                <div className="flex items-baseline gap-1 mb-2">
                  <span className="font-[var(--font-body)] text-5xl font-bold text-text-primary">{tier.price}</span>
                  <span className="font-[var(--font-mono)] text-xs text-text-muted">{tier.period}</span>
                </div>
                <div className="font-[var(--font-mono)] text-[10px] text-text-muted tracking-[2px] mb-6">
                  COLLATERAL: {tier.collateral}
                </div>
                <ul className="space-y-2">
                  {tier.features.map((f, j) => (
                    <li key={j} className="text-text-secondary text-sm flex items-center gap-2">
                      <span className="text-neon-red text-xs">▸</span>
                      {f}
                    </li>
                  ))}
                </ul>
              </button>
            ))}
          </div>

          {/* Checkout CTA */}
          <div className="mt-12 text-center">
            <Link
              href={`/checkout?tier=${TIERS[selectedTier].name.toLowerCase()}`}
              className="inline-block bg-neon-red text-white font-[var(--font-mono)] text-sm tracking-[4px] font-bold px-16 py-5 pulse-glow hover:bg-red-700 transition-colors"
            >
              LOCK IN {TIERS[selectedTier].name} TIER
            </Link>
          </div>
        </div>
      </section>

      {/* Social proof / urgency */}
      <section className="py-16 px-6 border-t border-neon-red/10">
        <div className="max-w-3xl mx-auto text-center">
          <p className="font-[var(--font-mono)] text-[10px] text-neon-red/60 tracking-[4px] mb-6">
            // TRANSMISSION END
          </p>
          <p className="text-text-secondary mb-8 text-lg">
            You have read this far. That means you know you are soft.
            <br />
            <span className="text-text-primary font-semibold">
              The Ustad knows it too.
            </span>
          </p>
          <p className="font-[var(--font-mono)] text-xs text-text-muted tracking-[2px]">
            BUILT WITH ML KIT • GEMINI AI • SUPABASE • RAZORPAY
          </p>
        </div>
      </section>
    </main>
  );
}
