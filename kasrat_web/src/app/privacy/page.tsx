import React from 'react';

export default function PrivacyPolicy() {
  return (
    <div className="bg-[#050505] text-[#FFFAF1] min-h-screen p-8 md:p-24 font-sans">
      <div className="max-w-3xl mx-auto space-y-8">
        <h1 className="text-4xl font-bold border-b border-[#FFFAF1]/10 pb-4">Privacy Policy</h1>
        <p className="text-[#FFFAF1]/60">Last Updated: May 2, 2026</p>

        <section className="space-y-4">
          <h2 className="text-2xl font-semibold">1. Introduction</h2>
          <p>
            Ustad AI ("we", "us", or "our") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, and safeguard your information when you use our mobile application and website.
          </p>
        </section>

        <section className="space-y-4">
          <h2 className="text-2xl font-semibold text-red-500">2. Camera Usage & Pose Detection</h2>
          <p>
            Our application requires access to your device's <strong>Camera</strong> to perform real-time pose detection. This is essential for:
          </p>
          <ul className="list-disc pl-6 space-y-2 text-[#FFFAF1]/80">
            <li>Verifying workout form (e.g., squat depth, pushup alignment).</li>
            <li>Counting repetitions automatically.</li>
            <li>Enforcing disciplinary protocols.</li>
          </ul>
          <p className="bg-[#1C1C1C] p-4 border-l-4 border-red-600 italic">
            <strong>Data Privacy Note:</strong> All camera processing is done locally on your device using on-device Machine Learning (ML Kit). <strong>We do NOT record, store, or transmit your video feed to our servers.</strong> Only the numerical result (e.g., "20 squats completed") is synced to your profile.
          </p>
        </section>

        <section className="space-y-4">
          <h2 className="text-2xl font-semibold">3. Information We Collect</h2>
          <ul className="list-disc pl-6 space-y-2 text-[#FFFAF1]/80">
            <li><strong>Account Information:</strong> Name and email via Google Authentication.</li>
            <li><strong>Performance Data:</strong> Number of reps, mission status, and workout history.</li>
            <li><strong>Payment Information:</strong> Transaction IDs for collateral deposits (processed securely via Razorpay).</li>
          </ul>
        </section>

        <section className="space-y-4">
          <h2 className="text-2xl font-semibold">4. How We Use Your Data</h2>
          <p>We use your data to maintain your "Unbroken" status, manage your collateral stakes, and provide the AI-driven drill instructor experience.</p>
        </section>

        <section className="space-y-4">
          <h2 className="text-2xl font-semibold">5. Contact Us</h2>
          <p>If you have questions about this policy, contact us at: <strong>arshdeepsinghex@gmail.com</strong></p>
        </section>

        <div className="pt-12 border-t border-[#FFFAF1]/10 text-center">
          <a href="/" className="text-red-500 hover:underline uppercase tracking-widest text-sm font-bold">Return to Terminal</a>
        </div>
      </div>
    </div>
  );
}
