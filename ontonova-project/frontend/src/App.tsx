import { AnimatePresence, motion } from "framer-motion";
import { Toaster } from "sonner";
import { CreateOntologyPanel } from "./components/CreateOntologyPanel";
import { InspectorPanel } from "./components/InspectorPanel";
import { LanguageSwitcher } from "./components/LanguageSwitcher";
import { Logo } from "./components/Logo";
import { OntologyCanvas } from "./components/OntologyCanvas";
import { ThemeToggle } from "./components/ThemeToggle";
import { Toolbar } from "./components/Toolbar";
import { TooltipProvider } from "./components/ui/Tooltip";
import { useOntologyStore } from "./store/ontologyStore";
import { useThemeStore } from "./store/themeStore";

// Shared "floating glass card" treatment for the header and both panels —
// the canvas is the full-bleed base layer, everything else floats above it
// with margin, rounded corners, blur and shadow instead of docking flush
// against the viewport edges with hard dividers.
const FLOATING_CARD = "rounded-2xl border border-border bg-surface/75 shadow-2xl backdrop-blur-xl";

function App() {
  const theme = useThemeStore((state) => state.theme);
  const selectedClassId = useOntologyStore((state) => state.selectedClassId);

  return (
    <TooltipProvider>
      <div className="relative h-screen overflow-hidden bg-bg text-text">
        <OntologyCanvas />

        <header
          className={`absolute inset-x-3 top-3 z-20 flex items-center justify-between gap-4 px-5 py-2.5 ${FLOATING_CARD}`}
        >
          <Logo />
          <div className="flex flex-1 items-center justify-end gap-4">
            <Toolbar />
            <div className="h-6 w-px bg-border" />
            <ThemeToggle />
            <LanguageSwitcher />
          </div>
        </header>

        <aside
          className={`absolute top-20 left-3 z-10 flex max-h-[calc(100vh-6rem)] w-80 flex-col overflow-y-auto p-5 ${FLOATING_CARD}`}
        >
          <CreateOntologyPanel />
        </aside>

        <AnimatePresence>
          {selectedClassId && (
            <motion.aside
              key="inspector"
              initial={{ opacity: 0, x: 16 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: 16 }}
              transition={{ duration: 0.2 }}
              className={`absolute top-20 right-3 z-10 max-h-[calc(100vh-6rem)] w-72 overflow-y-auto p-5 ${FLOATING_CARD}`}
            >
              <InspectorPanel />
            </motion.aside>
          )}
        </AnimatePresence>

        <Toaster theme={theme} position="bottom-right" richColors />
      </div>
    </TooltipProvider>
  );
}

export default App;
