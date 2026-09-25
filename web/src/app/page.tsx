import Header from "@/components/Header";
import Hero from "@/components/Hero";
import Features from "@/components/Features";
import Roles from "@/components/Roles";
import HowItWorks from "@/components/HowItWorks";
import CtaBanner from "@/components/CtaBanner";
import Footer from "@/components/Footer";

export default function Home() {
  return (
    <div className="flex flex-1 flex-col bg-background text-foreground">
      <Header />
      <main className="flex-1">
        <Hero />
        <Features />
        <Roles />
        <HowItWorks />
        <CtaBanner />
      </main>
      <Footer />
    </div>
  );
}
