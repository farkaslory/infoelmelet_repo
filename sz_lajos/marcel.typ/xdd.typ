\documentclass[12pt,a4paper]{article}

\usepackage[T1]{fontenc}
\usepackage[utf8]{inputenc}
\usepackage[hungarian]{babel}
\usepackage{lmodern}
\usepackage{microtype}
\usepackage{graphicx}
\graphicspath{{./}{upload/}}
\usepackage{subcaption}
\usepackage{geometry}
\geometry{margin=2.5cm}
\usepackage{tikz}
\usetikzlibrary{arrows.meta, positioning, decorations.pathreplacing}

\title{QAM-alapú aszinkron átvitel szimulációs elemzése}
\author{Marcell}
\date{}

\begin{document}
\maketitle

\section{Elméleti áttekintés: Az 1/2-es eltolás hatékonysága}

Az aszinkron modulációs rendszerekben az egymást átlapoló kódszavak és jelek interferenciájának kezelése kulcsfontosságú a vételi teljesítmény szempontjából. A matematikai elmélet szerint az egymást követő kódszavak közötti \textbf{$1/2$-es (50\%-os) időbeli eltolás} biztosítja a legkedvezőbb feltételeket a szekvenciális interferencia-kivonáshoz (SIC) és a dekódoláshoz, így ebben a pontban érhető el a legalacsonyabb bit-hibaarány (BER).

Ha az eltolás mértéke eltér az $1/2$-től (például $\Delta T < T/2$), akkor az átfedések mértéke egyenlőtlenné válik. Ilyenkor keletkezik olyan kis mértékű „rálógás” (ahol az átfedés $1/2$-nél lényegesen kisebb), amely során nem áll rendelkezésre elegendő közös információ az interferencia hatékony becsléséhez és kivonásához. Ez lerontja a szekvenciális dekódolás hatékonyságát, és növeli a hibaterjedés kockázatát.

Az $1/2$-es eltolás hatékonyságának főbb matematikai és rendszerszintű indokai:
\begin{enumerate}
    \item \textbf{Szimmetrikus áthallási eloszlás:} $1/2$-es eltolás esetén az $i$-edik kódszó pontosan egyenlő arányban (50--50\%-ban) fed át az őt megelőző $(i-1)$-edik és az őt követő $(i+1)$-edik kódszóval. Ezzel szemben a nem $1/2$-es eltolás egyenlőtlen áthallást eredményez, ahol a túl kicsi átfedésű szakaszok kihasználatlanul hagyják a kódszavak közötti korrelációt.
    \item \textbf{Optimális LLR-információmegosztás:} A szekvenciális iteratív dekódolás során a már sikeresen dekódolt kódszavak szimbólumai visszavonásra kerülnek a még nem dekódolt jelekből. Az $1/2$-es eltolás maximalizálja az egymásnak átadott feltételes információt (log-likelihood ratio, LLR), míg az $1/2$-nél kisebb átfedésű rálógások esetén az LLR-kérdéses információveszteség miatt megnő a hibaterjedési katasztrófa esélye.
    \item \textbf{Szimulációs igazolás:} A szimulációs BER-görbék $X = 1/2$ (vagy \texttt{oneBitPart} $\approx 0{,}5$) értéknél határozott minimumot (optimális pontot) mutatnak ideális példakódokra, ami igazolja az elméleti modellt.
\end{enumerate}

Az eltolás hatását, a kódszavak ($C_1, C_2, C_3$) elrendezését és az aszimmetrikus rálógásokat a \ref{fig:eltolas-elmelet}. ábra szemlélteti.

\begin{figure}[htbp]
    \centering
    % 1. Ideális eltolás
    \begin{subfigure}[b]{0.32\textwidth}
        \centering
        \begin{tikzpicture}[scale=0.45, >=Stealth]
            % C1 (alsó bal, kék)
            \draw[fill=blue!20, draw=blue!80!black, thick] (0, 0) rectangle (5, 0.8);
            \node at (2.5, 0.4) {\small $C_1$};
            
            % C3 (alsó jobb, zöld)
            \draw[fill=green!20, draw=green!80!black, thick] (5, 0) rectangle (10, 0.8);
            \node at (7.5, 0.4) {\small $C_3$};
            
            % C2 (felső, szimmetrikusan középen, piros)
            \draw[fill=red!20, draw=red!80!black, thick] (2.5, 1.2) rectangle (7.5, 2.0);
            \node at (5, 1.6) {\small $C_2$};
            
            % Vetítővonalak
            \draw[dashed, thick, gray] (2.5, 0.8) -- (2.5, 1.2);
            \draw[dashed, thick, gray] (5, 0) -- (5, 2.3);
            \draw[dashed, thick, gray] (7.5, 0.8) -- (7.5, 1.2);
            
            % Felső brace
            \draw[decorate, decoration={brace, amplitude=4pt, mirror}, thick] (7.5, 2.3) -- (5, 2.3) node[midway, above=5pt] {\small $\frac{T}{2}$};
            
            % Alsó brace
            \draw[decorate, decoration={brace, amplitude=4pt}, thick] (5, -0.1) -- (2.5, -0.1) node[midway, below=5pt] {\small $\frac{T}{2}$};
        \end{tikzpicture}
        \caption{Ideális $1/2$-es eltolás.}
        \label{fig:eltolas-idealis}
    \end{subfigure}
    \hfill
    % 2. Eltolás jobbra
    \begin{subfigure}[b]{0.32\textwidth}
        \centering
        \begin{tikzpicture}[scale=0.45, >=Stealth]
            % C1 (alsó bal, kék)
            \draw[fill=blue!20, draw=blue!80!black, thick] (0, 0) rectangle (5, 0.8);
            \node at (2.5, 0.4) {\small $C_1$};
            
            % C3 (alsó jobb, zöld)
            \draw[fill=green!20, draw=green!80!black, thick] (5, 0) rectangle (10, 0.8);
            \node at (7.5, 0.4) {\small $C_3$};
            
            % C2 (felső, jobbra tolva, piros)
            \draw[fill=red!20, draw=red!80!black, thick] (3.5, 1.2) rectangle (8.5, 2.0);
            \node at (6, 1.6) {\small $C_2$};
            
            % Vetítővonalak
            \draw[dashed, thick, gray] (5, 0) -- (5, 2.3);
            \draw[dashed, thick, gray] (8.5, 0.8) -- (8.5, 2.3);
            \draw[dashed, thick, gray] (3.5, 0.8) -- (3.5, 1.2);
            
            % Felső brace (C2 és C3 átfedése nagyobb, mint T/2)
            \draw[decorate, decoration={brace, amplitude=4pt, mirror}, thick] (8.5, 2.3) -- (5, 2.3) node[midway, above=5pt] {\small $>\frac{T}{2}$};
            
            % Alsó brace (C1 és C2 átfedése kisebb, mint T/2)
            \draw[decorate, decoration={brace, amplitude=4pt}, thick] (5, -0.1) -- (3.5, -0.1) node[midway, below=5pt] {\small $<\frac{T}{2}$};
        \end{tikzpicture}
        \caption{Eltolás jobbra.}
        \label{fig:eltolas-jobbra}
    \end{subfigure}
    \hfill
    % 3. Eltolás balra
    \begin{subfigure}[b]{0.32\textwidth}
        \centering
        \begin{tikzpicture}[scale=0.45, >=Stealth]
            % C1 (alsó bal, kék)
            \draw[fill=blue!20, draw=blue!80!black, thick] (0, 0) rectangle (5, 0.8);
            \node at (2.5, 0.4) {\small $C_1$};
            
            % C3 (alsó jobb, zöld)
            \draw[fill=green!20, draw=green!80!black, thick] (5, 0) rectangle (10, 0.8);
            \node at (7.5, 0.4) {\small $C_3$};
            
            % C2 (felső, balra tolva, piros)
            \draw[fill=red!20, draw=red!80!black, thick] (1.5, 1.2) rectangle (6.5, 2.0);
            \node at (4, 1.6) {\small $C_2$};
            
            % Vetítővonalak
            \draw[dashed, thick, gray] (5, 0) -- (5, 2.3);
            \draw[dashed, thick, gray] (1.5, 0.8) -- (1.5, 2.3);
            \draw[dashed, thick, gray] (6.5, 0.8) -- (6.5, 1.2);
            
            % Felső brace (C2 és C3 átfedése kisebb, mint T/2)
            \draw[decorate, decoration={brace, amplitude=4pt, mirror}, thick] (6.5, 2.3) -- (5, 2.3) node[midway, above=5pt] {\small $<\frac{T}{2}$};
            
            % Alsó brace (C1 és C2 átfedése nagyobb, mint T/2)
            \draw[decorate, decoration={brace, amplitude=4pt}, thick] (5, -0.1) -- (1.5, -0.1) node[midway, below=5pt] {\small $>\frac{T}{2}$};
        \end{tikzpicture}
        \caption{Eltolás balra.}
        \label{fig:eltolas-balra}
    \end{subfigure}
    \caption{A $C_1, C_2, C_3$ kódszavak elrendezése és rálógási viszonyai az ideális és aszimmetrikus esetekben.Az a) ábrán $C_1$-et és $C_2$-t ugyanolyan hatékonyan tudjuk dekódolni. A b) ábrán $C_1$-et megbízhatóbban tudjuk dekódolni, de ha ez sikerül, $C_2$-t kevésbé megbízhatóan. A c) ábrán $C_1$-et kevésbé megbízhatóbban tudjuk dekódolni, de ha ez sikerül, $C_2$-t megbízhatóbban.}
    \label{fig:eltolas-elmelet}
\end{figure}

Az elméleti megfontolásokat a szimulációs mérések is egyértelműen alátámasztják. A \ref{fig:eltolas-szimulacio}. ábrán látható, hogy a bithibaarány az eltolás függvényében szimmetrikus V-alakú görbét követ, amelynek globális minimuma a skála közepén (a $T/2$-es eltolásnak megfelelő felosztási pontban) található.

\begin{figure}[htbp]
    \centering
    \includegraphics[width=0.85\textwidth]{Vgorbe.png}
    \caption{A szimulált BER-értékek alakulása a kódszó-eltolás függvényében. A V-alakú görbe jól mutatja, hogy a legalacsonyabb hibaarány a skála közepén, az $1/2$-es eltolásnál érhető el.}
    \label{fig:eltolas-szimulacio}
\end{figure}
