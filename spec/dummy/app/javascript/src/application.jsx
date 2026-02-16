import React, {useEffect, useState} from "react";
import { createRoot } from "react-dom/client";
import { BrowserRouter, Link, Route, Routes } from "react-router-dom";
import HayaSelectV092 from "haya-select-v092/build/select";
import HayaSelectV094 from "haya-select-v094/build/select";
import HayaSelectV096 from "haya-select-v096/build/select";
import OutsideEyeProvider from "outside-eye/build/provider";
import versionV092 from "haya-select-v092/package.json";
import versionV094 from "haya-select-v094/package.json";
import versionV096 from "haya-select-v096/package.json";

const routes = [
  { path: "/haya-select/v092", label: "haya-select 1.0.92", version: versionV092.version, component: HayaSelectV092, id: "fruit_select_v092" },
  { path: "/haya-select/v094", label: "haya-select 1.0.94", version: versionV094.version, component: HayaSelectV094, id: "fruit_select_v094" },
  { path: "/haya-select/v096", label: "haya-select 1.0.96", version: versionV096.version, component: HayaSelectV096, id: "fruit_select_v096" },
  { path: "/haya-select/v096-delayed", label: "haya-select 1.0.96 delayed", version: versionV096.version, component: HayaSelectV096, id: "fruit_select_v096_delayed", delayedMount: true }
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
