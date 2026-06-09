import React, {useEffect, useState} from "react";
import { createRoot } from "react-dom/client";
import { BrowserRouter, Link, Route, Routes } from "react-router-dom";
import HayaSelect from "haya-select/build/select";
import OutsideEyeProvider from "outside-eye/build/provider";
import hayaSelectPackage from "haya-select/package.json";

const routes = [
  { path: "/haya-select", label: "haya-select", version: hayaSelectPackage.version, component: HayaSelect, id: "fruit_select" },
  { path: "/haya-select/delayed", label: "haya-select delayed", version: hayaSelectPackage.version, component: HayaSelect, id: "fruit_select_delayed", delayedMount: true }
];

function Header() {
  return (
    <header>
      <h1>Haya Select Dummy App</h1>
      <nav>
        {routes.map((route) => (
          <Link key={route.path} to={route.path} style={{ marginRight: "12px" }}>
            {route.label}
          </Link>
        ))}
      </nav>
    </header>
  );
}

function HomePage() {
  return (
    <main>
      <h2>React Router Routes</h2>
      <p>Use the links above to load each route and package version.</p>
    </main>
  );
}

function VersionPage({ component: HayaSelectComponent, delayedMount, id, label, version }) {
  const [showSelect, setShowSelect] = useState(!delayedMount);

  useEffect(() => {
    if (!delayedMount) {
      return;
    }

    const timeoutId = setTimeout(() => {
      setShowSelect(true);
    }, 200);

    return () => {
      clearTimeout(timeoutId);
    };
  }, [delayedMount]);

  return (
    <main>
      <h2>{label}</h2>
      <p data-testid="haya-select-version">Installed package version: {version}</p>
      <div style={{ maxWidth: "420px", marginTop: "10px" }}>
        {showSelect && (
          <HayaSelectComponent
            id={id}
            multiple={false}
            optionsPortal={false}
            options={[
              { value: "apple", text: "Apple" },
              { value: "banana", text: "Banana" },
              { value: "cherry", text: "Cherry" }
            ]}
            placeholder="Choose fruit"
          />
        )}
      </div>
    </main>
  );
}

function App() {
  return (
    <OutsideEyeProvider>
      <BrowserRouter>
        <Header />
        <Routes>
          <Route path="/" element={<HomePage />} />
          {routes.map((route) => (
            <Route
              key={route.path}
              path={route.path}
              element={
                <VersionPage
                  component={route.component}
                  delayedMount={route.delayedMount}
                  id={route.id}
                  label={route.label}
                  version={route.version}
                />
              }
            />
          ))}
        </Routes>
      </BrowserRouter>
    </OutsideEyeProvider>
  );
}

const rootElement = document.getElementById("dummy-react-root");
if (rootElement) {
  createRoot(rootElement).render(<App />);
}
