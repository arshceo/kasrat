"use client";

import { useSearchParams } from "next/navigation";
import { useState, Suspense } from "react";
import { supabase } from "@/lib/supabase";

declare global {
  interface Window {
    Razorpay: any;
  }
}

interface RazorpayOptions {
  key: string;
  amount: number;
  currency: string;
  name: string;
  description: string;
  prefill: { email: string; contact: string };
  theme: { color: string };
  handler: (response: RazorpayResponse) => void;
}

interface RazorpayInstance {
  open: () => void;
}

interface RazorpayResponse {
  razorpay_payment_id: string;
}

const TIERS: Record<string, { name: string; price: number; collateral: number; plan: string }> = {
  rookie: { name: "ROOKIE", price: 14900, collateral: 20000, plan: "monthly" },
  grunt: { name: "GRUNT", price: 29900, collateral: 50000, plan: "monthly" },
  commando: { name: "COMMANDO", price: 49900, collateral: 100000, plan: "monthly" },
};

function CheckoutContent() {
  const params = useSearchParams();
  const tierKey = params.get("tier") || "grunt";
  const tier = TIERS[tierKey] || TIERS.grunt;

  const [email, setEmail] = useState("");
  const [phone, setPhone] = useState("");
  const [step, setStep] = useState<"auth" | "pay" | "done">("auth");
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState("");

  const handleGoogleAuth = async () => {
    setIsLoading(true);
    setError("");
    try {
      const { error } = await supabase.auth.signInWithOAuth({
        provider: "google",
        options: {
          redirectTo: `${window.location.origin}/checkout?tier=${tierKey}&step=pay`,
        },
      });
      if (error) throw error;
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : "Auth failed");
      setIsLoading(false);
    }
  };

  const handlePayment = () => {
    const totalPaise = tier.price + tier.collateral;

    const options: RazorpayOptions = {
      key: "rzp_test_PLACEHOLDER",
      amount: totalPaise,
      currency: "INR",
      name: "USTAD AI",
      description: `${tier.name} Tier + ₹${tier.collateral / 100} Collateral`,
      prefill: { email, contact: phone },
      theme: { color: "#FF0000" },
      handler: async (response: RazorpayResponse) => {
        // Save to Supabase
        const user = (await supabase.auth.getUser()).data.user;
        if (user) {
          await supabase.from("subscriptions").insert({
            user_id: user.id,
            plan_type: tier.plan,
            amount: tier.price,
            razorpay_payment_id: response.razorpay_payment_id,
            status: "active",
            expires_at: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
          });
          await supabase.from("escrow").insert({
            user_id: user.id,
            amount: tier.collateral / 100,
            payment_id: response.razorpay_payment_id,
            payment_method: "razorpay",
            status: "held",
            refund_eligible_date: new Date(Date.now() + 28 * 24 * 60 * 60 * 1000).toISOString(),
          });
          await supabase.from("profiles").update({
            tier: tierKey,
            collateral_amount: tier.collateral / 100,
            is_paid: true,
          }).eq("id", user.id);
        }
        setStep("done");
      },
    };

    const rzp = new window.Razorpay(options);
    rzp.open();
  };

  return (
    <main className="min-h-screen grid-bg flex items-center justify-center px-6 py-12">
      <div className="w-full max-w-lg">
        {/* Header */}
        <div className="text-center mb-12">
          <div className="flex items-center justify-center gap-3 mb-4">
            <span className="w-2 h-2 rounded-full bg-neon-red shadow-[0_0_12px_rgba(255,0,0,0.6)]" />
            <span className="font-[var(--font-mono)] text-[10px] text-neon-red tracking-[4px]">
              W-03 // LOCK & LOAD
            </span>
            <span className="w-2 h-2 rounded-full bg-neon-red shadow-[0_0_12px_rgba(255,0,0,0.6)]" />
          </div>
          <h1 className="font-[var(--font-body)] text-4xl font-bold text-text-primary tracking-wider">
            {step === "done" ? "PROTOCOL ACTIVATED" : "FINALIZE ENROLLMENT"}
          </h1>
        </div>

        {step === "done" ? (
          <div className="border border-success/30 bg-success/5 p-12 text-center">
            <div className="text-5xl mb-4">✅</div>
            <h2 className="font-[var(--font-body)] text-2xl font-bold text-success mb-4">
              ENROLLMENT COMPLETE
            </h2>
            <p className="text-text-secondary mb-6">
              Download the app and sign in with the same Google account to begin your 28-day protocol.
            </p>
            <div className="border border-text-muted/20 p-6 bg-surface-glass">
              <p className="font-[var(--font-mono)] text-[10px] text-text-muted tracking-[3px] mb-2">
                YOUR TIER
              </p>
              <p className="font-[var(--font-body)] text-3xl font-bold text-neon-red">
                {tier.name}
              </p>
              <p className="font-[var(--font-mono)] text-xs text-text-muted mt-2 tracking-[2px]">
                COLLATERAL: ₹{tier.collateral / 100} HELD
              </p>
            </div>
            <a
              href="#"
              className="inline-block mt-8 bg-neon-red text-white font-[var(--font-mono)] text-sm tracking-[4px] px-12 py-4"
            >
              DOWNLOAD APP
            </a>
          </div>
        ) : (
          <>
            {/* Tier summary */}
            <div className="border border-neon-red/20 p-6 mb-8 bg-surface-glass">
              <div className="flex justify-between items-center mb-4">
                <span className="font-[var(--font-mono)] text-[10px] text-neon-red tracking-[4px]">
                  {tier.name} TIER
                </span>
                <span className="font-[var(--font-body)] text-2xl font-bold text-text-primary">
                  ₹{tier.price / 100}/mo
                </span>
              </div>
              <div className="border-t border-text-muted/10 pt-4 flex justify-between">
                <span className="text-text-muted text-sm">Subscription</span>
                <span className="text-text-secondary">₹{tier.price / 100}</span>
              </div>
              <div className="flex justify-between mt-2">
                <span className="text-text-muted text-sm">Collateral (refundable)</span>
                <span className="text-text-secondary">₹{tier.collateral / 100}</span>
              </div>
              <div className="border-t border-neon-red/20 pt-4 mt-4 flex justify-between">
                <span className="text-text-primary font-semibold">Total today</span>
                <span className="text-neon-red font-bold text-xl">
                  ₹{(tier.price + tier.collateral) / 100}
                </span>
              </div>
            </div>

            {error && (
              <div className="border border-danger/40 bg-danger/10 p-4 mb-6 text-center">
                <p className="font-[var(--font-mono)] text-xs text-danger tracking-[1px]">
                  {error}
                </p>
              </div>
            )}

            {step === "auth" ? (
              <div className="space-y-4">
                <button
                  onClick={handleGoogleAuth}
                  disabled={isLoading}
                  className="w-full bg-neon-red text-white font-[var(--font-mono)] text-sm tracking-[3px] font-bold py-5 pulse-glow hover:bg-red-700 transition-colors disabled:opacity-50 flex items-center justify-center gap-3"
                >
                  {isLoading ? (
                    <span className="animate-spin">⟳</span>
                  ) : (
                    <span className="text-lg font-bold">G</span>
                  )}
                  {isLoading ? "AUTHENTICATING..." : "CONTINUE WITH GOOGLE"}
                </button>
                <p className="text-center text-text-muted font-[var(--font-mono)] text-[9px] tracking-[2px]">
                  ALL PAYMENTS VIA WEB. NO APP STORE TAX.
                </p>
              </div>
            ) : (
              <div className="space-y-4">
                <input
                  type="email"
                  placeholder="Email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="w-full bg-surface border border-text-muted/20 text-text-primary px-5 py-4 font-[var(--font-mono)] text-sm focus:border-neon-red outline-none"
                />
                <input
                  type="tel"
                  placeholder="Phone (for UPI)"
                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                  className="w-full bg-surface border border-text-muted/20 text-text-primary px-5 py-4 font-[var(--font-mono)] text-sm focus:border-neon-red outline-none"
                />
                <button
                  onClick={handlePayment}
                  className="w-full bg-neon-red text-white font-[var(--font-mono)] text-sm tracking-[3px] font-bold py-5 pulse-glow hover:bg-red-700 transition-colors"
                >
                  PAY ₹{(tier.price + tier.collateral) / 100} VIA RAZORPAY
                </button>
              </div>
            )}
          </>
        )}
      </div>
    </main>
  );
}

export default function CheckoutPage() {
  return (
    <Suspense
      fallback={
        <main className="min-h-screen grid-bg flex items-center justify-center">
          <div className="animate-spin text-neon-red text-2xl">⟳</div>
        </main>
      }
    >
      <CheckoutContent />
    </Suspense>
  );
}
