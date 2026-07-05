import { motion } from "framer-motion";
import { useTranslation } from "react-i18next";
import { Logo } from "./Logo";

export function EmptyState() {
  const { t } = useTranslation();

  return (
    <motion.div
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.4 }}
      className="pointer-events-none absolute inset-0 z-10 flex flex-col items-center justify-center gap-4 text-center"
    >
      <Logo variant="full" className="scale-125 opacity-90" />
      <p className="max-w-xs text-sm text-text-muted">{t("app.tagline")}</p>
    </motion.div>
  );
}
