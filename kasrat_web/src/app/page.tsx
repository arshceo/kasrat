"use client";

import { useState, useEffect } from "react";
import Image from "next/image";
import Script from "next/script";
import { supabase } from "@/lib/supabase";

declare global {
  interface Window {
    Razorpay: any;
  }
}

export default function UstadTerminal() {
  const [code, setCode] = useState("");
  const [isValidated, setIsValidated] = useState(false);
  const [isVerifying, setIsVerifying] = useState(false);
  const [isProcessing, setIsProcessing] = useState(false);
  const [error, setError] = useState("");
  const [terminalData, setTerminalData] = useState<any>(null);
  const [pricing, setPricing] = useState({
    collateral: 200.00,
    fee: 25.00,
    currency: "INR",
    symbol: "₹",
    total: 225.00
  });
  const [step, setStep] = useState<'idle' | 'done'>('idle');
  const [isReviewer, setIsReviewer] = useState(false);

  // Detect region and set dynamic pricing
  useEffect(() => {
    const tz = Intl.DateTimeFormat().resolvedOptions().timeZone;
    const isIndianTimezone = tz === 'Asia/Kolkata' || tz === 'Asia/Calcutta';
    
    if (!isIndianTimezone) {
      setPricing({
        collateral: 25.00,
        fee: 2.00,
        currency: "USD",
        symbol: "$",
        total: 27.00
      });
    }
  }, []);

  const handleInitialize = async (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    const cleanCode = code.trim().replace(/[^a-zA-Z0-9]/g, '').toUpperCase();
    if (!cleanCode) return;

    // REVIEWER BYPASS: Phase 1 (Enter Magic Code)
    if (cleanCode === "REVIEW26") {
      setIsReviewer(true);
      setCode(""); // Clear it so they can enter their terminal code
      return;
    }

    setIsVerifying(true);
    setError("");
    
    try {
      // Real-time verification against Supabase
      const { data, error: fetchError } = await supabase
        .from("terminals")
        .select("id, user_id, user_name, code, protocol_id, protocol_title, duration_days, status")
        .eq("code", cleanCode)
        .maybeSingle();

      if (fetchError) throw new Error(fetchError.message || "SYSTEM_OFFLINE");
      if (!data) throw new Error("INVALID_DEPLOYMENT_CODE");

      setTerminalData(data);

      // REVIEWER BYPASS: Phase 2 (Automatic Authorization)
      if (isReviewer) {
        setIsProcessing(true);
        const { error: authError } = await supabase
          .from("terminals")
          .update({ 
            status: 'AUTHORIZED',
            updated_at: new Date().toISOString()
          })
          .eq("id", data.id);

        if (authError) throw authError;
        setStep('done');
        setIsProcessing(false);
        setIsVerifying(false);
        return;
      }

      setIsValidated(true);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setIsVerifying(false);
    }
  };

  const handlePayment = () => {
    if (typeof window === "undefined" || !window.Razorpay) {
      setError("PAYMENT_GATEWAY_OFFLINE. REFRESH.");
      return;
    }

    setIsProcessing(true);
    setError("");

    const options = {
      key: "rzp_test_SioNHcOX3Behki",
      amount: pricing.currency === "INR" ? pricing.total * 100 : pricing.total * 100, // Razorpay uses smallest unit
      currency: pricing.currency,
      name: "USTAD AI",
      description: "Mission Collateral Deployment",
      image: "/logo.png",
      handler: async function (response: any) {
        console.log("Payment Success:", response.razorpay_payment_id);
        
        if (terminalData?.user_id) {
          // Call server-side API route — uses service role key to bypass RLS.
          // The anon key used by this page CANNOT update another user's profile row.
          const res = await fetch("/api/authorize-deployment", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
              terminalId: terminalData.id,
              userId: terminalData.user_id,
              protocolId: terminalData.protocol_id,
              protocolTitle: terminalData.protocol_title,
              durationDays: terminalData.duration_days,
              paymentId: response.razorpay_payment_id,
            }),
          });

          const result = await res.json();

          if (!res.ok || result.error) {
            console.error("Authorization API Error:", result.error);
            setError(`AUTH_FAILED: ${result.error || "SERVER_ERROR"}`);
            setIsProcessing(false);
            return;
          }

          console.log("Deployment authorized successfully via server route.");
        }

        setStep('done');
      },
      prefill: {
        name: terminalData?.user_name || "Ustad User",
        email: "",
        contact: ""
      },
      theme: {
        color: "#0A0A0A"
      },
      modal: {
        ondismiss: function () {
          setIsProcessing(false);
        }
      }
    };

    try {
      const rzp = new window.Razorpay(options);
      rzp.open();
    } catch (err) {
      setError("PAYMENT_GATEWAY_ERROR");
      setIsProcessing(false);
    }
  };

  return (
    <div className="bg-[#050505] text-[#FFFAF1] font-body antialiased min-h-screen selection:bg-[#DC2626] selection:text-[#FFFAF1]">

      {/* Navigation */}
      <nav className="fixed transition-all duration-300 bg-[#050505]/80 w-full z-50 border-[#1C1C1C] border-b top-0 backdrop-blur-md">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-center md:justify-start items-center h-16 md:h-20">
            {/* Navbar Brand */}
            <div className="flex-shrink-0 flex items-center">
              <span className="font-brutal text-xl md:text-2xl uppercase tracking-tighter font-semibold text-[#FFFAF1] tracking-[-0.05em]">
                USTAD AI
              </span>
            </div>
          </div>
        </div>
      </nav>

      {/* Hero Terminal Section */}
      <header className="relative min-h-screen w-full flex flex-col items-center justify-start bg-[#050505] py-20 md:py-32">
        {/* Background Logo Watermark */}
        <div className="absolute inset-0 flex items-center justify-center opacity-[0.12] pointer-events-none select-none overflow-hidden z-0">
          <Image 
            src="/logo.png"
            alt=""
            width={1000}
            height={1000}
            className="w-[85vw] h-[85vw] max-w-[900px] max-h-[900px] object-contain"
            priority
          />
        </div>

        {/* Overlays */}
        <div className="absolute inset-0 bg-gradient-to-t from-[#050505] via-transparent to-transparent opacity-40 z-10"></div>
        <div className="absolute inset-0 bg-grain z-20"></div>

        {/* Content */}
        <div className="relative z-30 flex flex-col items-center justify-center text-center px-4 w-full max-w-5xl">
          {!isValidated ? (
            /* State 1: Code Entry */
            <>
              <h1 className="font-brutal text-6xl sm:text-7xl md:text-9xl uppercase tracking-tighter font-semibold text-[#FFFAF1] leading-[0.85] mb-6 drop-shadow-2xl">
                DEPLOY YOUR<br />COLLATERAL
              </h1>
              <p className="font-body text-base md:text-lg text-[#FFFAF1]/80 max-w-2xl mb-10 font-medium tracking-wide">
                Enter the 6-digit Deployment Code generated by your Ustad AI mobile terminal to initialize secure checkout.
              </p>

              <div className="w-full max-w-md space-y-6">
                <input
                  type="text"
                  value={code}
                  onChange={(e) => {
                    setCode(e.target.value.toUpperCase());
                    setError("");
                  }}
                  onKeyDown={(e) => e.key === 'Enter' && handleInitialize()}
                  placeholder={code === "REVIEW26" ? "ENTER TERMINAL CODE" : "e.g., BX9482"}
                  disabled={isVerifying}
                  className={`w-full bg-transparent border-4 ${error ? 'border-red-600' : 'border-[#FFFAF1]/30'} px-6 py-4 text-3xl md:text-4xl font-brutal uppercase text-center tracking-[0.2em] focus:border-[#FFFAF1] outline-none transition-all placeholder:text-[#FFFAF1]/10 ${isVerifying ? 'opacity-50' : 'opacity-100'}`}
                />

                {code === "REVIEW26" && (
                  <p className="text-yellow-500 font-brutal text-xs uppercase tracking-widest animate-pulse">
                    REVIEWER MODE ACTIVE. ENTER THE 6-DIGIT CODE FROM YOUR PHONE NEXT.
                  </p>
                )}

                {error && (
                  <p className="text-red-500 font-brutal text-xs uppercase tracking-widest animate-pulse">
                    {error}
                  </p>
                )}

                <button
                  onClick={() => handleInitialize()}
                  disabled={isVerifying || !code.trim()}
                  className="group relative flex items-center justify-center w-full py-5 bg-[#FFFAF1] text-[#0A0A0A] font-brutal uppercase text-lg font-bold tracking-tight overflow-hidden transition-all duration-300 hover:bg-[#DC2626] hover:text-white hover:shadow-[0_0_30px_rgba(220,38,38,0.4)] hover:scale-[1.02] active:scale-95 border border-transparent disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  <span className="relative z-10">
                    {isVerifying ? "VERIFYING_CONNECTION..." : "INITIALIZE PROTOCOL"}
                  </span>
                </button>
              </div>
            </>
          ) : (
            /* State 2: Checkout Cart */
            <>
              <h1 className="font-brutal text-6xl sm:text-7xl md:text-9xl uppercase tracking-tighter font-semibold text-[#FFFAF1] leading-[0.85] mb-6 drop-shadow-2xl">
                PROTOCOL<br />LOCKED
              </h1>
              <p className="font-body text-base md:text-lg text-[#FFFAF1]/80 max-w-2xl mb-10 font-medium tracking-wide">
                Welcome, Operator {terminalData?.user_name?.split(' ')[0] || 'AUTHORIZED_USER'}. Secure your collateral to activate the AI kinetic engine.
              </p>

              <div className="w-full max-w-md space-y-6">
                <button
                  onClick={() => setIsValidated(false)}
                  className="flex items-center gap-2 text-[10px] text-[#FFFAF1]/40 hover:text-[#FFFAF1] uppercase tracking-widest font-bold transition-all group/back"
                >
                  <span className="group-hover/back:-translate-x-1 transition-transform">←</span>
                  BACK_TO_TERMINAL
                </button>

                <div className="bg-[#1C1C1C] border border-[#FFFAF1]/20 p-6 md:p-10 text-left w-full shadow-2xl relative">
                  {/* Brutalist accents */}
                  <div className="absolute top-0 right-0 w-8 h-8 border-t border-r border-[#FFFAF1]/30"></div>
                  <div className="absolute bottom-0 left-0 w-8 h-8 border-b border-l border-[#FFFAF1]/30"></div>

                  <div className="space-y-6 font-body">
                    <div className="bg-[#262626] p-4 border-l-4 border-white mb-8">
                      <div className="flex justify-between items-start mb-4">
                        <div>
                          <p className="text-[10px] text-white/50 uppercase tracking-widest mb-1 font-bold">OPERATOR</p>
                          <p className="text-xl font-bold text-white tracking-tighter uppercase leading-none">{terminalData?.user_name || 'AUTHENTICATED OPERATOR'}</p>
                        </div>
                        <div className="text-right">
                          <p className="text-[10px] text-white/50 uppercase tracking-widest mb-1 font-bold">STATUS</p>
                          <p className="text-[10px] font-bold text-yellow-500 uppercase tracking-widest">PENDING_DEPLOYMENT</p>
                        </div>
                      </div>
                      <div className="h-px bg-white/10 mb-4"></div>
                      <p className="text-[10px] text-white/50 uppercase tracking-widest mb-1 font-bold">MISSION_DIRECTIVE</p>
                      <p className="text-sm font-bold text-white tracking-tight uppercase">{terminalData?.protocol_title || 'CHALLENGE'}</p>
                      <p className="text-[10px] text-white/50 uppercase tracking-widest mt-2 font-bold">INTEL: {terminalData?.duration_days || '--'} DAY OPERATION</p>
                    </div>

                    <div className="flex justify-between items-start gap-4">
                      <span className="text-[#FFFAF1]/60 text-sm uppercase tracking-widest font-semibold">Requirement</span>
                      <span className="text-[#FFFAF1]/60 text-sm uppercase tracking-widest font-semibold text-right">Amount</span>
                    </div>

                    <div className="h-px bg-[#FFFAF1]/10"></div>
                    
                    {step === 'done' ? (
                      <div className="space-y-6 text-center py-8">
                        <div className="flex justify-center mb-4">
                          <div className="w-16 h-16 rounded-full border-2 border-green-500 flex items-center justify-center text-green-500 text-3xl animate-pulse">
                            ✓
                          </div>
                        </div>
                        <h3 className="text-2xl font-bold text-[#FFFAF1] tracking-tighter">DEPLOYMENT AUTHORIZED</h3>
                        <p className="text-[#FFFAF1]/60 text-sm">MISSION PROTOCOL LOCKED. RETURN TO APP TO COMMENCE OPERATIONS.</p>
                        <button 
                          onClick={() => window.location.reload()}
                          className="mt-4 text-[#FFFAF1]/40 text-[10px] uppercase tracking-widest hover:text-white"
                        >
                          [ RESET TERMINAL ]
                        </button>
                      </div>
                    ) : (
                      <>
                        <div className="flex justify-between items-center">
                          <span className="text-[#FFFAF1] text-base font-medium">Mission Collateral</span>
                          <span className="text-[#FFFAF1] font-bold">{pricing.symbol}{pricing.collateral.toFixed(2)}</span>
                        </div>
                        <p className="text-[10px] text-[#FFFAF1]/40 uppercase tracking-wider -mt-4">
                          Refundable upon {terminalData?.duration_days || '30'}-day survival
                        </p>

                        <div className="flex justify-between items-center">
                          <span className="text-[#FFFAF1] text-sm font-medium opacity-60">AI Engine & Processing Fee</span>
                          <span className="text-[#FFFAF1] font-bold opacity-60">{pricing.symbol}{pricing.fee.toFixed(2)}</span>
                        </div>
                        <p className="text-[10px] text-[#FFFAF1]/40 uppercase tracking-wider -mt-4">
                          {pricing.currency === 'INR' ? 'Incl. GST + Cloud Infrastructure' : 'AI Processing + Intl. Transaction'}
                        </p>

                        <div className="h-px bg-[#FFFAF1]/10 my-2"></div>

                        <div className="flex justify-between items-center">
                          <span className="text-[#FFFAF1] text-xl font-bold uppercase tracking-tight">TOTAL STAKE</span>
                          <span className="text-[#FFFAF1] text-2xl font-bold tracking-tighter">{pricing.symbol}{pricing.total.toFixed(2)}</span>
                        </div>

                        {/* Aggressive Primary CTA */}
                        <button
                          onClick={handlePayment}
                          disabled={isProcessing}
                          className="w-full mt-8 py-5 bg-[#FFFAF1] text-[#0A0A0A] font-brutal uppercase text-lg font-bold tracking-tight hover:bg-[#DC2626] hover:text-white hover:shadow-[0_0_30px_rgba(220,38,38,0.4)] transition-all duration-300 active:scale-95 border border-transparent disabled:opacity-50"
                        >
                          {isProcessing ? "SECURE_CONNECTION..." : `AUTHORIZE ${pricing.symbol}${pricing.total.toFixed(0)} DEPOSIT`}
                        </button>
                      </>
                    )}

                    <p className="mt-4 text-center text-[10px] text-[#FFFAF1]/40 uppercase tracking-widest font-medium">
                      Payments processed via secure UPI mandate under founder Arshdeep Singh. No weak links.
                    </p>

                  </div>


                </div>
              </div>
            </>
          )}

          {/* Shared Trust Anchors: App Store & Play Store */}
          <div className="mt-12 flex flex-col sm:flex-row items-center justify-center gap-4 w-full max-w-md">
            {/* Google Play Button */}
            <a href="#" className="flex items-center gap-3 bg-black border border-[#FFFAF1]/20 hover:border-[#FFFAF1] transition-all px-6 py-3 rounded-xl w-full sm:w-auto justify-center group shadow-2xl">
              <svg className="w-8 h-8" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                <path d="M3.609 1.814c-.198.209-.312.518-.312.906v18.56c0 .388.114.697.312.906l.055.05L14.28 11.62v-.24L3.664 1.764l-.055.05z" fill="#3bccff" />
                <path d="M17.828 15.17l-3.548-3.55v-.24l3.548-3.55.068.038 4.195 2.385c1.2.68 1.2 1.795 0 2.476l-4.195 2.385-.068.056z" fill="#ffd400" />
                <path d="M17.896 15.114l-3.616-3.614-10.671 10.671c.394.417 1.042.467 1.78.048l12.507-7.105z" fill="#ff3344" />
                <path d="M17.896 8.886L5.389 1.781c-.738-.42-1.386-.37-1.78.048L14.28 12.5l3.616-3.614z" fill="#48ff48" />
              </svg>
              <div className="text-left">
                <div className="text-[10px] uppercase tracking-tight text-[#FFFAF1]/80 font-medium leading-none mb-1">GET IT ON</div>
                <div className="text-lg font-bold font-body leading-none text-[#FFFAF1] tracking-tight">Google Play</div>
              </div>
            </a>

            {/* App Store Button (Locked/Coming Soon) */}
            <div className="flex items-center gap-3 bg-black border border-[#FFFAF1]/20 px-6 py-3 rounded-xl w-full sm:w-auto justify-center opacity-60 relative overflow-hidden group shadow-2xl cursor-help">
              <div className="absolute inset-0 bg-black/40 backdrop-blur-[1px] z-20 flex items-center justify-center">
                <span className="text-[8px] font-brutal uppercase tracking-[0.2em] text-[#FFFAF1] bg-[#0A0A0A] px-2 py-1 border border-[#FFFAF1]/20">COMING SOON</span>
              </div>
              <svg className="w-8 h-8 text-white z-10" viewBox="0 0 384 512" fill="currentColor">
                <path d="M318.7 268.7c-.2-36.7 16.4-64.4 50-84.8-18.8-26.9-47.2-41.7-84.7-44.6-35.5-2.8-74.3 20.7-88.5 20.7-15 0-49.4-19.7-76.4-19.7C63.3 141.2 4 184.8 4 273.5q0 39.3 14.4 81.2c12.8 36.7 59 126.7 107.2 125.2 25.2-.6 43-17.9 75.8-17.9 31.8 0 48.3 17.9 76.4 17.9 48.6-.7 90.4-82.5 102.6-119.3-65.2-30.7-61.7-90-61.7-91.9zm-56.6-164.2c27.3-32.4 24.8-61.9 24-72.5-24.1 1.4-52 16.4-67.9 34.9-17.5 19.8-27.8 44.3-25.6 71.9 26.1 2 49.9-11.4 69.5-34.3z" />
              </svg>
              <div className="text-left z-10">
                <div className="text-[10px] tracking-tight text-[#FFFAF1]/80 font-medium leading-none mb-1">Download on the</div>
                <div className="text-lg font-bold font-body leading-none text-[#FFFAF1] tracking-tight">App Store</div>
              </div>
            </div>
          </div>
        </div>

        {/* Scroll Indicator */}
        <div className="absolute bottom-8 left-1/2 -translate-x-1/2 flex flex-col items-center gap-2 opacity-60">
          <span className="font-brutal text-xs uppercase tracking-tight">System Online</span>
          <div className="w-px h-8 bg-gradient-to-b from-[#FFFAF1] to-transparent"></div>
        </div>
      </header>

      {/* The Manifesto / Mission Briefing (Red Theme, Zero Jargon) */}
      <section className="w-full bg-[#050505] py-24 px-4 sm:px-6 lg:px-8 border-t border-[#1C1C1C] relative z-20">
        <div className="max-w-5xl mx-auto">
          <div className="text-center mb-16">
            <h2 className="font-brutal text-3xl md:text-5xl uppercase tracking-tighter font-bold leading-none mb-6">
              <span className="bg-[#DC2626] text-[#FFFAF1] px-6 py-3 inline-block shadow-[6px_6px_0px_0px_rgba(220,38,38,0.2)] -rotate-1">
                WHAT IS USTAD AI?
              </span>
            </h2>
            <p className="font-body text-base text-[#FFFAF1]/50 max-w-xl mx-auto">
              Not a fitness tracker. A digital drill instructor. We use AI and your own money to force you out of bed.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-6 md:gap-8">
            {/* Pillar 1 */}
            <div className="flex flex-col items-center text-center gap-3 bg-[#0A0A0A] border border-[#1C1C1C] border-t-4 border-t-[#DC2626] p-8 transition-transform hover:-translate-y-1 duration-300">
              <div className="text-5xl text-[#DC2626] font-brutal leading-none">01</div>
              <h3 className="font-brutal text-xl uppercase tracking-tight font-bold text-[#FFFAF1]">Uncheatable AI</h3>
              <p className="font-body text-sm text-[#FFFAF1]/60 leading-relaxed">
                The camera tracks your bones. If your hips don't drop, the squat doesn't count. You cannot fake it.
              </p>
            </div>

            {/* Pillar 2 */}
            <div className="flex flex-col items-center text-center gap-3 bg-[#0A0A0A] border border-[#1C1C1C] border-t-4 border-t-[#DC2626] p-8 transition-transform hover:-translate-y-1 duration-300">
              <div className="text-5xl text-[#DC2626] font-brutal leading-none">02</div>
              <h3 className="font-brutal text-xl uppercase tracking-tight font-bold text-[#FFFAF1]">The Cash Stake</h3>
              <p className="font-body text-sm text-[#FFFAF1]/60 leading-relaxed">
                Deposit {pricing.symbol}{pricing.total.toFixed(0)}. Survive {terminalData?.duration_days || '30'} days, get your collateral back. Quit early, the machine keeps your stake.
              </p>
            </div>

            {/* Pillar 3 */}
            <div className="flex flex-col items-center text-center gap-3 bg-[#0A0A0A] border border-[#1C1C1C] border-t-4 border-t-[#DC2626] p-8 transition-transform hover:-translate-y-1 duration-300">
              <div className="text-5xl text-[#DC2626] font-brutal leading-none">03</div>
              <h3 className="font-brutal text-xl uppercase tracking-tight font-bold text-[#FFFAF1]">The Penalty</h3>
              <p className="font-body text-sm text-[#FFFAF1]/60 leading-relaxed">
                You have a strict 2-hour window after your alarm. Miss the clock, forfeit your cash. No excuses.
              </p>
            </div>
          </div>

          <div className="mt-16 text-center">
            <button 
              onClick={() => window.scrollTo({ top: 0, behavior: 'smooth' })}
              className="text-[#FFFAF1]/50 hover:text-[#DC2626] font-brutal uppercase text-sm tracking-widest transition-colors border-b border-transparent hover:border-[#DC2626] pb-1"
            >
              Return to Terminal
            </button>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="w-full bg-[#050505] border-t border-[#1C1C1C] py-20 px-4 sm:px-6 lg:px-8">
        <div className="max-w-7xl mx-auto flex flex-col items-center gap-10">
          <div className="flex flex-col items-center gap-4 text-center">
            <a href="#" className="font-brutal text-3xl md:text-4xl uppercase tracking-tighter font-semibold text-[#FFFAF1]">USTAD AI</a>
            <p className="font-body text-xs text-[#FFFAF1]/40 uppercase tracking-[0.3em] font-medium">Master your physical vessel.</p>
          </div>

          {/* Store Buttons in Footer */}
          <div className="flex flex-col sm:flex-row items-center justify-center gap-4 w-full max-w-md">
            {/* Google Play Button */}
            <a href="#" className="flex items-center gap-3 bg-black border border-[#FFFAF1]/20 hover:border-[#FFFAF1] transition-all px-6 py-3 rounded-xl w-full sm:w-auto justify-center group shadow-2xl">
              <svg className="w-8 h-8" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                <path d="M3.609 1.814c-.198.209-.312.518-.312.906v18.56c0 .388.114.697.312.906l.055.05L14.28 11.62v-.24L3.664 1.764l-.055.05z" fill="#3bccff" />
                <path d="M17.828 15.17l-3.548-3.55v-.24l3.548-3.55.068.038 4.195 2.385c1.2.68 1.2 1.795 0 2.476l-4.195 2.385-.068.056z" fill="#ffd400" />
                <path d="M17.896 15.114l-3.616-3.614-10.671 10.671c.394.417 1.042.467 1.78.048l12.507-7.105z" fill="#ff3344" />
                <path d="M17.896 8.886L5.389 1.781c-.738-.42-1.386-.37-1.78.048L14.28 12.5l3.616-3.614z" fill="#48ff48" />
              </svg>
              <div className="text-left">
                <div className="text-[10px] uppercase tracking-tight text-[#FFFAF1]/80 font-medium leading-none mb-1">GET IT ON</div>
                <div className="text-lg font-bold font-body leading-none text-[#FFFAF1] tracking-tight">Google Play</div>
              </div>
            </a>

            {/* App Store Button (Locked/Coming Soon) */}
            <div className="flex items-center gap-3 bg-black border border-[#FFFAF1]/20 px-6 py-3 rounded-xl w-full sm:w-auto justify-center opacity-60 relative overflow-hidden group shadow-2xl cursor-help">
              <div className="absolute inset-0 bg-black/40 backdrop-blur-[1px] z-20 flex items-center justify-center">
                <span className="text-[8px] font-brutal uppercase tracking-[0.2em] text-[#FFFAF1] bg-[#0A0A0A] px-2 py-1 border border-[#FFFAF1]/20">COMING SOON</span>
              </div>
              <svg className="w-8 h-8 text-white z-10" viewBox="0 0 384 512" fill="currentColor">
                <path d="M318.7 268.7c-.2-36.7 16.4-64.4 50-84.8-18.8-26.9-47.2-41.7-84.7-44.6-35.5-2.8-74.3 20.7-88.5 20.7-15 0-49.4-19.7-76.4-19.7C63.3 141.2 4 184.8 4 273.5q0 39.3 14.4 81.2c12.8 36.7 59 126.7 107.2 125.2 25.2-.6 43-17.9 75.8-17.9 31.8 0 48.3 17.9 76.4 17.9 48.6-.7 90.4-82.5 102.6-119.3-65.2-30.7-61.7-90-61.7-91.9zm-56.6-164.2c27.3-32.4 24.8-61.9 24-72.5-24.1 1.4-52 16.4-67.9 34.9-17.5 19.8-27.8 44.3-25.6 71.9 26.1 2 49.9-11.4 69.5-34.3z" />
              </svg>
              <div className="text-left z-10">
                <div className="text-[10px] tracking-tight text-[#FFFAF1]/80 font-medium leading-none mb-1">Download on the</div>
                <div className="text-lg font-bold font-body leading-none text-[#FFFAF1] tracking-tight">App Store</div>
              </div>
            </div>
          </div>

          <div className="w-full flex flex-col md:flex-row justify-between items-center pt-8 border-t border-[#FFFAF1]/5 gap-6">
            <div className="flex gap-8 text-sm font-mono text-[#FFFAF1]/40 uppercase tracking-widest">
              <a href="/privacy" className="hover:text-red-500 transition-colors">Privacy Policy</a>
              <span className="select-none text-[#FFFAF1]/10">|</span>
              <a href="mailto:arshdeepsinghex@gmail.com" className="hover:text-red-500 transition-colors">Support</a>
            </div>
            <p className="font-body text-[10px] text-[#FFFAF1]/20 tracking-[0.2em] uppercase">
              © 2026 USTAD AI. ALL RIGHTS RESERVED.
            </p>
          </div>
        </div>
      </footer>

      {/* Load Razorpay SDK */}
      <Script
        src="https://checkout.razorpay.com/v1/checkout.js"
        strategy="lazyOnload"
      />
    </div>
  );
}
