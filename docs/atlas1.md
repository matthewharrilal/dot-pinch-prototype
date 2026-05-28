 ATLAS #1 — The Sandbox Pinch Primitive                                                                                                                                                                             
                                                                                
  Recursive Implication Trace (Full Mode, Ultrathink)                                                                                                                                                                
                                                            
  This document is the orchestrator's enumeration + root interrogation + dispatch map. Wave 2 parallel branch agents are dispatched at the end of this section. Wave 3 (synthesis) and Wave 4 (metacognitive) follow
  after Wave 2 returns. The final three artifacts (Structured Map, Consequence Narrative, Heat Map Summary) are assembled at the close.                                                                              
                                                                                                                                                                                                                     
  ---                                                                                                                                                                                                                
  STEP 1 — Pre-Trace Enumeration (the trace's scope)                                                                                                                                                                 
                                                                                                                                                                                                                     
  1.1 — File enumeration (every file touched across all rounds)
                                              
  Path: DotPinchPrototype/App/SceneDelegate.swift                                                                                                                                                                    
  Role: Composition root for sandbox; SandboxViewController (the proving ground) and GradientView (CAGradientLayer-backed page field). Wires gradient stops, pinkMask/greyMask reveal masks, panel + corner radius +
    clipsToBounds + shadow, dormantLabel reparenting, debug readout, 4 subscribers, the pinch recognizer, the state schedule.                                                                                        
  Changed in rounds: All rounds; final state holds C4 cellBottomLift=195, E1' gradient stops, E3' transition-width 0.10, D1 dormantLabel reparenting, F1 shadow wiring + viewDidLayoutSubviews shadowPath update, F2
    metadataHidden: true, 10-state demo schedule                                                                                                                                                                     
  Sandbox-only / Shared: Sandbox-only. sandboxMode flag selects this VC; real app uses V2RootViewController.                                                                                                         
  ────────────────────────────────────────
  Path: DotPinchPrototype/Conversation/ChatBody/ChatBubbleStackView.swift                                                                                                                                            
  Role: Two classes: (a) ChatBubbleStackView (the scrollview + UIStackView holding bubbles); (b) ContentScalerView (the Track A primitive — owns bodyContent, dormantBlur, dormantLabel, scalingSurface,             
    blurAnimator); plus the curves (scaleCurve, blurCurve, contentDissolveAlpha, labelInAlpha, shadowOpacityCurve, panelHeightCurve, panelWidthCurve, pinkMaskAlpha, greyMaskAlpha, topFadeBoundary) and the
    ScalingSurface (the p-driver SSoT).                                                                                                                                                                              
  Changed in rounds: All rounds; final state holds all curves with their eased shoulders, dissolve refactor to bodyContent.alpha + dormantBlur.alpha (CSV.alpha=1 neutral), F2 metadataHidden plumbing
  Sandbox-only / Shared: Shared (the file). But ChatBubbleView invocation path: real app uses default metadataHidden=false; sandbox sets true. The curves themselves are sandbox-tuned but the shapes are portable.  
  ────────────────────────────────────────                  
  Path: DotPinchPrototype/Conversation/ChatBody/ChatBubbleView.swift
  Role: Per-message bubble renderer (role label + body label + time label). Final state: gained metadataHidden: Bool = false parameter; when true, role and time labels are not added and bodyLabel constrains
    directly to bubble bounds.
  Changed in rounds: F2                                                                                                                                                                                              
  Sandbox-only / Shared: Shared with default-false; only sandbox sets true.
  ────────────────────────────────────────                                                                                                                                                                           
  Path: DotPinchPrototype/DesignSystem/Theme.swift          
  Role: Tokens: Theme.Page.top (cool grey), Theme.Page.surface (#ede9ee), Theme.Page.bottom (#cc9194 — corrected from spec's claimed S=71 to measured S=29), Theme.Page.gradientGreyMid (RGB 217,213,218),
    Theme.Page.gradientPinkLight (RGB 197,166,168). Theme.Cell.fill, Theme.Cell.shadowColor (UIColor.black.cgColor), Theme.Cell.shadowOpacityCellRest (0.06 — dialed from 0.12 in F1), Theme.Cell.shadowOffset
    (CGSize(0, 4)), Theme.Cell.shadowRadius (8 — dialed from 12 in F1). Text colors, typography (bubbleRole, bubbleBody, bubbleTime, composerHint, destinationDate, serif destinationBody), Radius.card=25, symbol   
    affordances.
  Changed in rounds: E1 (gradient bottom corrected), E1' (gradientGreyMid + gradientPinkLight added), F1 (shadow opacity 0.12→0.06, radius 12→8)                                                                     
  Sandbox-only / Shared: Shared for the real app's tokens. Sandbox uses these directly.
  ────────────────────────────────────────
  Path: DotPinchPrototype/Conversation/Data/DummyConversationLoader.swift
  Role: Loads four sample conversations; first one (today) has 21 messages including the "Good morning! Just a quick check-in about your daily exercise goal..." final message, with curatedSummary = "Good morning 
    check-in, daily exercise nudge, 20-minute workout suggestions".
  Changed in rounds: Untouched in primitive rounds.                                                                                                                                                                  
  Sandbox-only / Shared: Stand-in. Replaced at integration. F2 finding banks the spec for the real renderer (paragraph-style flow); the dummy content itself stays as-is for the sandbox.
  ────────────────────────────────────────                                                                                                                                                                           
  Path: DotPinchPrototype/Conversation/Models/Conversation.swift, Message.swift
  Role: Data models. Message.Role = .user / .assistant. Conversation carries messages + curatedSummary + displayDate.
  Changed in rounds: Untouched.
  Sandbox-only / Shared: Shared.                                                                                                                                                                                     
  ────────────────────────────────────────
  Path: DotPinchPrototype/App/V2RootViewController.swift                                                                                                                                                             
  Role: Real-app root. Explicitly out of scope for this trace (the integration target trace is a separate symmetric pass per the user's prompt).
  Changed in rounds: Untouched.
  Sandbox-only / Shared: Shared, untraced here.                                                                                                                                                                      
  
  Phantom-watch (1.1): No additional files modified by the primitive work. Tests files (Tests/V2/*) exist but were not touched in primitive rounds and are the real-app's invariant tests — surface as               
  untraced-but-shared.                                      

  1.2 — Constants (with file:line, current value, original/changed, round, channel, sacredness)                                                                                                                      
                                          
  A. Geometry constants (SandboxViewController in SceneDelegate.swift)                                                                                                                                               
                                                                                                                                                                                                                     
  ┌─────────────────────┬──────┬────────────────┬────────────┬─────────┬─────────────────────┬────────────────────────────────────────────────────────────────────────────────────┐
  │        Name         │ Line │    Current     │  Original  │  Round  │       Channel       │                                      Sacred?                                       │                                  
  ├─────────────────────┼──────┼────────────────┼────────────┼─────────┼─────────────────────┼────────────────────────────────────────────────────────────────────────────────────┤
  │ viewportW           │ 63   │ 393            │ —          │ initial │ sandbox geometry    │ stand-in (iPhone 16 logical)                                                       │                                  
  ├─────────────────────┼──────┼────────────────┼────────────┼─────────┼─────────────────────┼────────────────────────────────────────────────────────────────────────────────────┤
  │ viewportH           │ 64   │ 852            │ —          │ initial │ sandbox geometry    │ stand-in (iPhone 16 logical)                                                       │                                  
  ├─────────────────────┼──────┼────────────────┼────────────┼─────────┼─────────────────────┼────────────────────────────────────────────────────────────────────────────────────┤
  │ safeAreaTopInset    │ 65   │ 59             │ —          │ initial │ sandbox geometry    │ stand-in                                                                           │                                  
  ├─────────────────────┼──────┼────────────────┼────────────┼─────────┼─────────────────────┼────────────────────────────────────────────────────────────────────────────────────┤                                  
  │ safeAreaBottomInset │ 66   │ 34             │ —          │ initial │ sandbox geometry    │ stand-in                                                                           │                                  
  ├─────────────────────┼──────┼────────────────┼────────────┼─────────┼─────────────────────┼────────────────────────────────────────────────────────────────────────────────────┤                                  
  │ safeAreaH           │ 67   │ 759 (computed) │ —          │ initial │ sandbox geometry    │ stand-in                                                                           │                                  
  ├─────────────────────┼──────┼────────────────┼────────────┼─────────┼─────────────────────┼────────────────────────────────────────────────────────────────────────────────────┤
  │ cellWidth           │ 68   │ 350            │ (no prior) │ C5      │ cell-rest geometry  │ sandbox stand-in (89.5% of viewport; aspect partner)                               │                                  
  ├─────────────────────┼──────┼────────────────┼────────────┼─────────┼─────────────────────┼────────────────────────────────────────────────────────────────────────────────────┤
  │ cellHeight          │ 69   │ 226            │ (no prior) │ C5      │ cell-rest geometry  │ sandbox stand-in (gives aspect 1.549; ref target 1.55–1.60)                        │                                  
  ├─────────────────────┼──────┼────────────────┼────────────┼─────────┼─────────────────────┼────────────────────────────────────────────────────────────────────────────────────┤
  │ cellBottomLift      │ 77   │ 195            │ 50         │ C4      │ cell-rest placement │ stand-in for real list slot (banks: cell.bot at 77.1% of viewport)                 │                                  
  ├─────────────────────┼──────┼────────────────┼────────────┼─────────┼─────────────────────┼────────────────────────────────────────────────────────────────────────────────────┤
  │ cellCornerRadius    │ 78   │ 28             │ —          │ initial │ cell-rest geometry  │ stand-in (real app: Theme.Radius.card=25; small mismatch banked but not addressed) │                                  
  ├─────────────────────┼──────┼────────────────┼────────────┼─────────┼─────────────────────┼────────────────────────────────────────────────────────────────────────────────────┤
  │ pinchFullScale      │ 55   │ 0.3            │ —          │ initial │ gesture mapping     │ sandbox-only                                                                       │                                  
  ├─────────────────────┼──────┼────────────────┼────────────┼─────────┼─────────────────────┼────────────────────────────────────────────────────────────────────────────────────┤
  │ logScaleSpan        │ 56   │ -log(0.3)      │ —          │ initial │ gesture mapping     │ sandbox-only                                                                       │                                  
  └─────────────────────┴──────┴────────────────┴────────────┴─────────┴─────────────────────┴────────────────────────────────────────────────────────────────────────────────────┘
                                                                                                                                                                                                                     
  B. Curve breakpoints (ContentScalerView in ChatBubbleStackView.swift)
                                                                                                                                                                                                                     
  ┌──────────────────────────┬──────┬─────────┬─────────────┬───────┬───────────────────────┬────────────────────────────────────────────────────────────────────────────────────┐
  │           Name           │ Line │ Current │  Original   │ Round │        Channel        │                                      Sacred?                                       │                                   
  ├──────────────────────────┼──────┼─────────┼─────────────┼───────┼───────────────────────┼────────────────────────────────────────────────────────────────────────────────────┤
  │ scaleOnsetP              │ 190  │ 0.12    │ —           │ A1    │ scale                 │ ✓ verified-closed                                                                  │                                   
  ├──────────────────────────┼──────┼─────────┼─────────────┼───────┼───────────────────────┼────────────────────────────────────────────────────────────────────────────────────┤
  │ scaleFullP               │ 191  │ 0.45    │ —           │ A1    │ scale                 │ ✓ verified-closed                                                                  │                                   
  ├──────────────────────────┼──────┼─────────┼─────────────┼───────┼───────────────────────┼────────────────────────────────────────────────────────────────────────────────────┤
  │ scaleAtCellRest          │ 199  │ 0.40    │ —           │ A1    │ scale                 │ ✓ verified-closed                                                                  │                                   
  ├──────────────────────────┼──────┼─────────┼─────────────┼───────┼───────────────────────┼────────────────────────────────────────────────────────────────────────────────────┤                                   
  │ blurOnsetP               │ 197  │ 0.40    │ (was ~0.30) │ A6    │ blur                  │ ✓ verified-closed                                                                  │                                   
  ├──────────────────────────┼──────┼─────────┼─────────────┼───────┼───────────────────────┼────────────────────────────────────────────────────────────────────────────────────┤                                   
  │ blurFullP                │ 198  │ 0.44    │ —           │ A6    │ blur                  │ ✓ verified-closed                                                                  │                                   
  ├──────────────────────────┼──────┼─────────┼─────────────┼───────┼───────────────────────┼────────────────────────────────────────────────────────────────────────────────────┤
  │ blurMaxFraction          │ 260  │ 0.45    │ (was ~0.80) │ A7    │ blur                  │ ✓ verified-closed (joint with dissolveFloor)                                       │                                   
  ├──────────────────────────┼──────┼─────────┼─────────────┼───────┼───────────────────────┼────────────────────────────────────────────────────────────────────────────────────┤
  │ dissolveOnsetP           │ 330  │ 0.42    │ —           │ A5    │ dissolve              │ ✓ verified-closed                                                                  │                                   
  ├──────────────────────────┼──────┼─────────┼─────────────┼───────┼───────────────────────┼────────────────────────────────────────────────────────────────────────────────────┤
  │ dissolveFullP            │ 331  │ 0.46    │ —           │ A5    │ dissolve              │ ✓ verified-closed                                                                  │                                   
  ├──────────────────────────┼──────┼─────────┼─────────────┼───────┼───────────────────────┼────────────────────────────────────────────────────────────────────────────────────┤
  │ dissolveFloor            │ 341  │ 0.40    │ —           │ A5    │ dissolve              │ ✓ verified-closed (joint with blurMaxFraction; banked target ~225 lum at end-of-A) │                                   
  ├──────────────────────────┼──────┼─────────┼─────────────┼───────┼───────────────────────┼────────────────────────────────────────────────────────────────────────────────────┤
  │ bodyOutOnsetP            │ 373  │ 0.61    │ 0.85        │ D1'   │ body-out              │ ✓ verified-closed (re-banked to match ref body-clear at 0.66)                      │                                   
  ├──────────────────────────┼──────┼────────────────────────────────┼─────────────┼───────┼───────────────────────┼────────────────────────────────────────────────────────────────────────────────────┤
  │ bodyOutFullP             │ 374  │ 0.66                           │ 0.91        │ D1'   │ body-out              │ ✓ verified-closed (ref body cleared by p=0.66)                                     │            
  ├──────────────────────────┼──────┼────────────────────────────────────┼─────────────┼───────┼───────────────────────┼────────────────────────────────────────────────────────────────────────────────────┤
  │ labelInOnsetP            │ 426  │ 0.71                               │ 0.93        │ D1'   │ label-in              │ ✓ verified-closed (de-gated; integration extends to ~0.86 with sparkle)            │        
  ├──────────────────────────┼──────┼─────────────────────────────────────┼─────────────┼───────┼───────────────────────┼────────────────────────────────────────────────────────────────────────────────────┤
  │ labelInFullP             │ 427  │ 0.78                                │ 1.00        │ D1'   │ label-in              │ ✓ verified-closed (preserves ref's 0.07 label-fade span)                           │       
  ├──────────────────────────┼──────┼─────────────────────────────────────┼─────────────┼───────┼───────────────────────┼────────────────────────────────────────────────────────────────────────────────────┤
  │ shadowOnsetP             │ 437  │ 0.85                                │ —           │ F1    │ shadow                │ ✓ verified-closed (smoothstep)                                                     │       
  ├──────────────────────────┼──────┼─────────────────────────────────────┼─────────────┼───────┼───────────────────────┼────────────────────────────────────────────────────────────────────────────────────┤
  │ shadowFullP              │ 438  │ 1.00                                │ —           │ F1    │ shadow                │ ✓ verified-closed                                                                  │       
  ├──────────────────────────┼──────┼─────────────────────────────────────┼─────────────┼───────┼───────────────────────┼────────────────────────────────────────────────────────────────────────────────────┤
  │ panelContractionOnsetP   │ 482  │ 0.50                                │ (was 0.45)  │ B1    │ panel height          │ ✓ verified-closed (hold beat 0.46–0.50)                                            │       
  ├──────────────────────────┼──────┼─────────────────────────────────────┼─────────────┼───────┼───────────────────────┼────────────────────────────────────────────────────────────────────────────────────┤
  │ panelContractionEaseEndP │ 483  │ 0.55                                │ —           │ B1    │ panel height shoulder │ ✓ verified-closed (C¹ shoulder)                                                    │       
  ├──────────────────────────┼──────┼─────────────────────────────────────┼─────────────┼───────┼───────────────────────┼────────────────────────────────────────────────────────────────────────────────────┤
  │ panelWidthOnsetP         │ 454  │ 0.62                                │ —           │ C6    │ panel width           │ ✓ verified-closed                                                                  │       
  ├──────────────────────────┼──────┼─────────────────────────────────────┼─────────────┼───────┼───────────────────────┼────────────────────────────────────────────────────────────────────────────────────┤
  │ panelWidthEaseEndP       │ 528  │ 0.67                                │ —           │ C6    │ panel width shoulder  │ ✓ verified-closed (matched form to panelHeight shoulder)                           │       
  ├──────────────────────────┼──────┼─────────────────────────────────────┼─────────────┼───────┼───────────────────────┼────────────────────────────────────────────────────────────────────────────────────┤
  │ pinkMaskRecedeOnsetP     │ 547  │ 0.50                                │ —           │ E3    │ pink reveal           │ ✓ verified-closed (matched-span shoulder with panelContraction)                    │       
  ├──────────────────────────┼──────┼─────────────────────────────────────┼─────────────┼───────┼───────────────────────┼────────────────────────────────────────────────────────────────────────────────────┤
  │ pinkMaskRecedeFullP      │ 548  │ 0.65                                │ —           │ E3    │ pink reveal           │ ✓ verified-closed                                                                  │       
  ├──────────────────────────┼──────┼─────────────────────────────────────┼─────────────┼───────┼───────────────────────┼────────────────────────────────────────────────────────────────────────────────────┤
  │ pinkMaskOnsetEaseEndP    │ 603  │ 0.55                                │ —           │ B1'   │ pink shoulder         │ ✓ verified-closed                                                                  │       
  ├──────────────────────────┼──────┼─────────────────────────────────────┼─────────────┼───────┼───────────────────────┼────────────────────────────────────────────────────────────────────────────────────┤
  │ pinkMaskEndEaseStartP    │ 604  │ 0.60                                │ —           │ B1'   │ pink shoulder         │ ✓ verified-closed                                                                  │       
  ├──────────────────────────┼──────┼─────────────────────────────────────┼─────────────┼───────┼───────────────────────┼────────────────────────────────────────────────────────────────────────────────────┤
  │ greyMaskRecedeOnsetP     │ 553  │ 0.54                                │ 0.75        │ E3    │ grey reveal           │ ✓ verified-closed (near-co-onset with pink, matching ref)                          │       
  ├──────────────────────────┼──────┼─────────────────────────────────────┼─────────────┼───────┼───────────────────────┼────────────────────────────────────────────────────────────────────────────────────┤
  │ greyMaskRecedeFullP      │ 554  │ 0.90                                │ —           │ E3    │ grey reveal           │ ✓ verified-closed                                                                  │       
  ├──────────────────────────┼──────┼─────────────────────────────────────┼─────────────┼───────┼───────────────────────┼────────────────────────────────────────────────────────────────────────────────────┤
  │ greyMaskOnsetEaseEndP    │ 677  │ 0.59                                │ —           │ E3    │ grey shoulder         │ ✓ verified-closed                                                                  │       
  ├──────────────────────────┼──────┼─────────────────────────────────────┼─────────────┼───────┼───────────────────────┼────────────────────────────────────────────────────────────────────────────────────┤
  │ greyMaskEndEaseStartP    │ 678  │ 0.85                                │ —           │ E3    │ grey shoulder         │ ✓ verified-closed                                                                  │       
  ├──────────────────────────┼──────┼─────────────────────────────────────┼─────────────┼───────┼───────────────────────┼────────────────────────────────────────────────────────────────────────────────────┤
  │ topFadeBoundaryAtRest    │ 754  │ 0.10                                │ —           │ A3    │ top-fade              │ ✓ verified-closed (resting fade present)                                           │       
  ├──────────────────────────┼──────┼─────────────────────────────────────┼─────────────┼───────┼───────────────────────┼────────────────────────────────────────────────────────────────────────────────────┤
  │ topFadeBoundaryAtFull    │ 755  │ 1.00                                │ —           │ A3    │ top-fade              │ ✓ verified-closed                                                                  │       
  ├──────────────────────────┼──────┼─────────────────────────────────────┼─────────────┼───────┼───────────────────────┼────────────────────────────────────────────────────────────────────────────────────┤
  │ topFadeFullAtP           │ 756  │ 0.50                                │ —           │ A3    │ top-fade              │ ✓ verified-closed                                                                  │       
  ├──────────────────────────┼──────┼─────────────────────────────────────┼─────────────┼───────┼───────────────────────┼────────────────────────────────────────────────────────────────────────────────────┤
  │ topFadeKnotsP            │ 758  │ [0.00, 0.17, 0.27, 0.40, 0.50]      │ —           │ A4    │ top-fade Hermite      │ ✓ verified-closed                                                                  │       
  ├──────────────────────────┼──────┼─────────────────────────────────────┼─────────────┼───────┼───────────────────────┼────────────────────────────────────────────────────────────────────────────────────┤
  │ topFadeKnotsY            │ 759  │ [0.10, 0.167, 0.700, 0.833, 1.000]  │ —           │ A4    │ top-fade Hermite      │ ✓ verified-closed (B1–B5 cluster, B6 handoff to dissolve at 0.40)                  │       
  ├──────────────────────────┼──────┼─────────────────────────────────────┼─────────────┼───────┼───────────────────────┼────────────────────────────────────────────────────────────────────────────────────┤
  │ topFadeTangents          │ 760  │ [0.394, 0.734, 1.710, 1.270, 1.670] │ —           │ A4    │ top-fade Hermite      │ ✓ verified-closed (Fritsch-Carlson tangents)                                       │       
  └──────────────────────────┴──────┴─────────────────────────────────────┴─────────────┴───────┴───────────────────────┴────────────────────────────────────────────────────────────────────────────────────┘
                                                                                                                                                                                                                     
  C. Theme constants (Theme.swift)                          
                                                                                                                                                                                                                     
  ┌──────────────────────────────────┬──────┬──────────────────────────┬───────────────────────────┬───────────────────────────────────┬─────────────────────────┬──────────────────────────────────────────────┐  
  │               Name               │ Line │         Current          │         Original          │               Round               │         Channel         │                   Sacred?                    │    
  ├──────────────────────────────────┼──────┼──────────────────────────┼───────────────────────────┼───────────────────────────────────┼─────────────────────────┼──────────────────────────────────────────────┤  
  │ Theme.Page.top                   │ 11   │ RGB(186,184,187)         │ —                         │ E1                                │ gradient top            │ ✓ closed                                     │    
  ├──────────────────────────────────┼──────┼──────────────────────────┼───────────────────────────┼───────────────────────────────────┼─────────────────────────┼──────────────────────────────────────────────┤  
  │ Theme.Page.surface               │ 14   │ RGB(237,233,238)         │ —                         │ initial                           │ panel fill, masks fill  │ ✓ closed (the "page locally lifted" surface) │  
  ├──────────────────────────────────┼──────┼──────────────────────────┼───────────────────────────┼───────────────────────────────────┼─────────────────────────┼──────────────────────────────────────────────┤  
  │ Theme.Page.bottom                │ 22   │ RGB(204,145,148) =       │ (corrected from claimed   │ E1                                │ gradient bottom         │ ✓ closed (the S=71→S=29 correction is the    │  
  │                                  │      │ #cc9194                  │ S=71 spec)                │                                   │                         │ deeper finding)                              │    
  ├──────────────────────────────────┼──────┼──────────────────────────┼───────────────────────────┼───────────────────────────────────┼─────────────────────────┼──────────────────────────────────────────────┤    
  │ Theme.Page.gradientGreyMid       │ 30   │ RGB(217,213,218)         │ (introduced E1')          │ E1'                               │ gradient mid-grey stop  │ ✓ closed                                     │    
  │                                  │      │                          │                           │                                   │ @ 0.50                  │                                              │    
  ├──────────────────────────────────┼──────┼──────────────────────────┼───────────────────────────┼───────────────────────────────────┼─────────────────────────┼──────────────────────────────────────────────┤  
  │ Theme.Page.gradientPinkLight     │ 37   │ RGB(197,166,168)         │ (introduced E1')          │ E1'                               │ gradient light-pink     │ ✓ closed                                     │    
  │                                  │      │                          │                           │                                   │ stop @ 0.85             │                                              │
  ├──────────────────────────────────┼──────┼──────────────────────────┼───────────────────────────┼───────────────────────────────────┼─────────────────────────┼──────────────────────────────────────────────┤    
  │ Theme.Cell.fill                  │ 43   │ #f6efef                  │ —                         │ (unused at primitive layer; panel │ candidate phantom       │                                              │
  │                                  │      │                          │                           │  uses surface)                    │                         │                                              │    
  ├──────────────────────────────────┼──────┼──────────────────────────┼───────────────────────────┼───────────────────────────────────┼─────────────────────────┼──────────────────────────────────────────────┤
  │ Theme.Cell.shadowColor           │ 48   │ UIColor.black.cgColor    │ —                         │ F1                                │ shadow                  │ ✓ closed                                     │    
  ├──────────────────────────────────┼──────┼──────────────────────────┼───────────────────────────┼───────────────────────────────────┼─────────────────────────┼──────────────────────────────────────────────┤
  │ Theme.Cell.shadowOpacityCellRest │ 49   │ 0.06                     │ 0.12                      │ F1                                │ shadow                  │ ✓ closed (4 iterations)                      │
  ├──────────────────────────────────┼──────┼──────────────────────────┼───────────────────────────┼───────────────────────────────────┼─────────────────────────┼──────────────────────────────────────────────┤
  │ Theme.Cell.shadowOffset          │ 50   │ CGSize(0, 4)             │ —                         │ F1                                │ shadow                  │ ✓ closed                                     │
  ├──────────────────────────────────┼──────┼──────────────────────────┼───────────────────────────┼───────────────────────────────────┼─────────────────────────┼──────────────────────────────────────────────┤    
  │ Theme.Cell.shadowRadius          │ 51   │ 8                        │ 12                        │ F1                                │ shadow                  │ ✓ closed (dialed for tighter                 │
  │                                  │      │                          │                           │                                   │                         │ bottom-concentration)                        │    
  └──────────────────────────────────┴──────┴──────────────────────────┴───────────────────────────┴───────────────────────────────────┴─────────────────────────┴──────────────────────────────────────────────┘
                                                                                                                                                                                                                     
  D. Other constants in SceneDelegate                       
                                                                                                                                                                                                                     
  ┌───────────────────────────────┬────────┬───────────────────────────────────┬───────┬───────────────────────────┬───────────────────────────────────────────────────────────────────────────────────────────┐
  │             Name              │  Line  │              Current              │ Round │          Channel          │                                           Notes                                           │     
  ├───────────────────────────────┼────────┼───────────────────────────────────┼───────┼───────────────────────────┼───────────────────────────────────────────────────────────────────────────────────────────┤
  │ Gradient locations            │ 122    │ [0.0, 0.50, 0.55, 0.85, 1.0]      │ E1'   │ gradient stops            │ ✓ closed                                                                                  │     
  ├───────────────────────────────┼────────┼───────────────────────────────────┼───────┼───────────────────────────┼───────────────────────────────────────────────────────────────────────────────────────────┤
  │ Gradient start/end points     │ 123,   │ (0.5, 0) → (0.5, 1)               │ E1'   │ gradient direction        │ vertical                                                                                  │
  │                               │ 124    │                                   │       │                           │                                                                                           │
  ├───────────────────────────────┼────────┼───────────────────────────────────┼───────┼───────────────────────────┼───────────────────────────────────────────────────────────────────────────────────────────┤
  │ greyMask height               │ 207    │ viewportH * 0.20 = 170.4pt        │ E3    │ grey mask geometry        │ covers top 20%                                                                            │     
  ├───────────────────────────────┼────────┼───────────────────────────────────┼───────┼───────────────────────────┼───────────────────────────────────────────────────────────────────────────────────────────┤     
  │ pinkMask height               │ 213    │ viewportH * 0.25 = 213pt          │ E3    │ pink mask geometry        │ covers bottom 25%                                                                         │     
  ├───────────────────────────────┼────────┼───────────────────────────────────┼───────┼───────────────────────────┼───────────────────────────────────────────────────────────────────────────────────────────┤     
  │ transitionWidth (pinkMask     │ 281    │ 0.10                              │ E3'   │ pink reveal mask          │ ✓ closed (closes 22.5% pink reveal at full, matching ref 22.6%)                           │
  │ gradient)                     │        │                                   │       │ transition width          │                                                                                           │     
  ├───────────────────────────────┼────────┼───────────────────────────────────┼───────┼───────────────────────────┼───────────────────────────────────────────────────────────────────────────────────────────┤
  │ Pink mask initial locations   │ 142    │ [1.0, 1.0]                        │ E3    │ pink reveal mask state    │ initial-clamped opaque                                                                    │     
  ├───────────────────────────────┼────────┼───────────────────────────────────┼───────┼───────────────────────────┼───────────────────────────────────────────────────────────────────────────────────────────┤
  │ Grey mask initial locations   │ 158    │ [0.0, 0.0]                        │ E3    │ grey reveal mask state    │ initial-clamped opaque                                                                    │     
  ├───────────────────────────────┼────────┼───────────────────────────────────┼───────┼───────────────────────────┼───────────────────────────────────────────────────────────────────────────────────────────┤
  │ Initial shadowOpacity         │ 168    │ 0                                 │ F1    │ shadow                    │ starts at 0 (curve drives during gesture)                                                 │     
  ├───────────────────────────────┼────────┼───────────────────────────────────┼───────┼───────────────────────────┼───────────────────────────────────────────────────────────────────────────────────────────┤
  │ dormantLabel font (sandbox    │ 189    │ .systemFont(ofSize: 17, weight:   │ D1    │ label                     │ overrides Theme.Typography.destinationDate (F3 serif) — system font is primitive          │     
  │ override)                     │        │ .medium)                          │       │                           │ stand-in; F3 serif is integration                                                         │
  ├───────────────────────────────┼────────┼───────────────────────────────────┼───────┼───────────────────────────┼───────────────────────────────────────────────────────────────────────────────────────────┤     
  │ dormantLabel 20pt panel       │ 228,   │ leading/trailing ≥20pt            │ D1    │ label layout              │ per-panel-bounds positioning                                                              │
  │ margins                       │ 229    │                                   │       │                           │                                                                                           │     
  └───────────────────────────────┴────────┴───────────────────────────────────┴───────┴───────────────────────────┴───────────────────────────────────────────────────────────────────────────────────────────┘

  E. F2 flag                                                                                                                                                                                                         
  
  ┌────────────────────────────────────┬─────────────────────────────────────────────────────────────────────────────────────────────────┬──────────────────────────────┬───────┬───────────────────────────────┐    
  │                Name                │                                            Location                                             │            Value             │ Round │             Notes             │
  ├────────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────┼──────────────────────────────┼───────┼───────────────────────────────┤
  │ metadataHidden (parameter)         │ ChatBubbleView.swift:9, ChatBubbleStackView.swift:80,96, ChatBubbleStackView.swift:923          │ default false, sandbox sets  │ F2    │ reversible; real app gets     │
  │                                    │ (ContentScalerView), SceneDelegate.swift:236                                                    │ true                         │       │ default-false                 │
  ├────────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────┼──────────────────────────────┼───────┼───────────────────────────────┤
  │ Same-role spacing (when            │ ChatBubbleStackView.swift:104                                                                   │ 4pt                          │ F2    │ tight grouping                │
  │ metadataHidden)                    │                                                                                                 │                              │       │                               │
  ├────────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────┼──────────────────────────────┼───────┼───────────────────────────────┤    
  │ Role-transition spacing (when      │ ChatBubbleStackView.swift:104                                                                   │ 16pt (=Layout.bubbleSpacing) │ F2    │ standard gap                  │
  │ metadataHidden)                    │                                                                                                 │                              │       │                               │    
  └────────────────────────────────────┴─────────────────────────────────────────────────────────────────────────────────────────────────┴──────────────────────────────┴───────┴───────────────────────────────┘
                                                                                                                                                                                                                     
  1.3 — Curve functions                                                                                                                                                                                              
  
  Function: scaleCurve(p)                                                                                                                                                                                            
  File:line: 447                                                                                                                                                                                                 
  Mathematical form: Linear within [0.12, 0.45]; clamped 1.0 below, 0.40 above                                                                                                                                   
  Domain → Range: p∈[0,1] → s∈[0.40, 1.0]                                                                                                                                                                            
  Knots/Tangents: endpoints only                                                                                                                                                                                 
  Monotone?: ↘ (decreasing)                                                                                                                                                                                          
  C¹?: NO at boundaries (velocity kinks at 0.12 and 0.45)                                                                                                                                                       
  Channel: scale                                                                                                                                                                                                
  Eased shoulders: None — A1 closed without easing                                                                                                                                                                   
  ────────────────────────────────────────                                                                                                                                                                      
  Function: blurCurve(p)                                                                                                                                                                                             
  File:line: 262                                                                                                                                                                                                
  Mathematical form: 5-knot piecewise cubic Hermite, Fritsch-Carlson tangents                                                                                                                                        
  Domain → Range: p∈[0,1] → f∈[0, 0.45]                                                                                                                                                                        
  Knots/Tangents: K0(0, 0), K1(0.33, 0.010), K2(0.40, 0.050), K3(0.44, 0.45), K4(0.50, 0.45); m₀=d₀=0.0303, m₁=harm=0.0575, m₂=harm (runtime), m₃=0, m₄=0                                                      
  Monotone?: ↗ (non-decreasing)                                                                                                                                                                                
  C¹?: YES                                                                                                                                                                                                           
  Channel: blur                                                                                                                                                                                                
  Eased shoulders: gentle lead-in + crash + plateau via Hermite                                                                                                                                                      
  ────────────────────────────────────────                                                                                                                                                                     
  Function: contentDissolveAlpha(p)                                                                                                                                                                            
  File:line: 376
  Mathematical form: Piecewise smoothstep: 1.0 (p≤0.42), smoothstep down to 0.40 over [0.42, 0.46], hold at 0.40, smoothstep down to 0.0 over [0.61, 0.66]                                                           
  Domain → Range: p∈[0,1] → α∈[0, 1.0]    
  Knots/Tangents: onset 0.42, full 0.46, body-out onset 0.61, body-out full 0.66, floor 0.40                                                                                                                         
  Monotone?: ↘ (non-increasing)                                                                                                                                                                                      
  C¹?: YES (smoothstep C¹ at endpoints)
  Channel: dissolve + body-out                                                                                                                                                                                       
  Eased shoulders: smoothstep is the easing                 
  ────────────────────────────────────────
  Function: labelInAlpha(p)
  File:line: 429
  Mathematical form: Smoothstep within [0.71, 0.78]; clamped 0 below, 1 above
  Domain → Range: p∈[0,1] → α∈[0, 1]
  Knots/Tangents: onset 0.71, full 0.78
  Monotone?: ↗
  C¹?: YES
  Channel: label-in
  Eased shoulders: smoothstep
  ────────────────────────────────────────
  Function: shadowOpacityCurve(p)
  File:line: 440
  Mathematical form: Smoothstep within [0.85, 1.00]; clamped 0 below, 1 above
  Domain → Range: p∈[0,1] → m∈[0, 1] (multiplier on shadowOpacityCellRest)
  Knots/Tangents: onset 0.85, full 1.00
  Monotone?: ↗
  C¹?: YES
  Channel: shadow
  Eased shoulders: smoothstep
  ────────────────────────────────────────
  Function: panelHeightCurve(p)               
  File:line: 485                          
  Mathematical form: Cubic Hermite shoulder + linear: 0 below 0.50; Hermite shoulder over [0.50, 0.55] from 0 (m=0) → 0.10 (m=slope=2.0); linear at slope 2.0 to 1.0
  Domain → Range: p∈[0,1] → tH∈[0, 1]                                                                                                                                                                                
  Knots/Tangents: onset 0.50, ease-end 0.55, slope=2.0
  Monotone?: ↗ (non-decreasing)                                                                                                                                                                                      
  C¹?: YES at shoulder and linear-join; clamp at endpoints is hard
  Channel: panel height (vertical contraction)
  Eased shoulders: onset shoulder only
  ────────────────────────────────────────
  Function: panelWidthCurve(p)                
  File:line: 530                          
  Mathematical form: Same form as panelHeightCurve shifted to [0.62, 0.67]; slope = 1/(1−0.62) ≈ 2.632
  Domain → Range: p∈[0,1] → tW∈[0, 1]                                                                                                                                                                                
  Knots/Tangents: onset 0.62, ease-end 0.67
  Monotone?: ↗                                                                                                                                                                                                       
  C¹?: YES at shoulder                                      
  Channel: panel width
  Eased shoulders: onset shoulder only
  ────────────────────────────────────────
  Function: pinkMaskAlpha(p)                  
  File:line: 606                          
  Mathematical form: Hermite onset shoulder [0.50, 0.55] + linear middle [0.55, 0.60] + Hermite end shoulder [0.60, 0.65]; recede slope = −1/0.15 ≈ −6.67
  Domain → Range: p∈[0,1] → α∈[1.0, 0] (mask boundary value)                                                                                                                                                         
  Knots/Tangents: (0.50, 1.0)→(0.55, 0.667), linear to (0.60, 0.333), shoulder to (0.65, 0.0)
  Monotone?: ↘ (non-increasing)                                                                                                                                                                                      
  C¹?: YES (matched-span symmetric Hermite shoulders)       
  Channel: pink reveal (used as mask gradient location, NOT view.alpha)
  Eased shoulders: onset + end
  ────────────────────────────────────────
  Function: greyMaskAlpha(p)                  
  File:line: 680                          
  Mathematical form: Same construction as pinkMaskAlpha with knots at [0.54, 0.59, 0.85, 0.90]; recede slope = −1/0.36 ≈ −2.78
  Domain → Range: p∈[0,1] → α∈[1.0, 0]                                                                                                                                                                               
  Knots/Tangents: (0.54, 1.0)→(0.59, ye)→(0.85, ys)→(0.90, 0)
  Monotone?: ↘                                                                                                                                                                                                       
  C¹?: YES                                                  
  Channel: grey reveal (mask gradient location)
  Eased shoulders: onset + end
  ────────────────────────────────────────
  Function: topFadeBoundary(p)                
  File:line: 762                          
  Mathematical form: 5-knot piecewise cubic Hermite, Fritsch-Carlson tangents
  Domain → Range: p∈[0,1] → y∈[0.10, 1.0]                                                                                                                                                                            
  Knots/Tangents: K0(0, 0.10), K1(0.17, 0.167), K2(0.27, 0.700), K3(0.40, 0.833), K4(0.50, 1.000); m=[0.394, 0.734, 1.710, 1.270, 1.670]
  Monotone?: ↗                                                                                                                                                                                                       
  C¹?: YES                                                  
  Channel: top-fade boundary (mask gradient location[1])
  Eased shoulders: Hermite throughout; cluster-then-hold shape

  Note on scaleCurve: it is the ONLY linear curve and has velocity kinks at its boundaries (0.12, 0.45). These kinks are present in active gesture range. Closed status was set against the reference's
  similarity-transform character; the kinks are tolerated. Phantom check / metacognitive risk: this is the single non-C¹ active curve in the system; principle (b) — "interactive curves are 
  pure/monotonic/smooth(C¹) functions of p" — is partially violated here.
                                                                                                                                                                                                                     
  1.4 — View-hierarchy changes
                                                                                                                                                                                                                     
  ┌─────────────────────────────────────────────┬────────────────────────────────────────────────────────────────────────────────────────┬──────────┬──────────────────────────────────────────────────────────┐  
  │                      Change                      │                                      File:line                                       │  Round   │                   Load-bearing role                    │ 
  ├──────────────────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────┼──────────┼────────────────────────────────────────────────────────┤ 
  │                                                  │ SceneDelegate.swift:188 (scaler.dormantLabel.removeFromSuperview());                 │          │ Label rides panel's contracting bounds. Decoupled from │ 
  │ dormantLabel reparented from CSV → panel         │ SceneDelegate.swift:190 (panel.addSubview(scaler.dormantLabel)); constraints at      │ D1       │  CSV.alpha so dissolve doesn't fade label; D1          │ 
  │                                                  │ 226-229                                                                              │          │ architectural fix.                                     │    
  ├──────────────────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────┼──────────┼────────────────────────────────────────────────────────┤ 
  │ panel.clipsToBounds = true retained              │ SceneDelegate.swift:164                                                              │ initial  │ Load-bearing for cornerRadius cropping of contents     │    
  │                                                  │                                                                                      │ + F1     │ during contraction                                     │    
  ├──────────────────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────┼──────────┼────────────────────────────────────────────────────────┤ 
  │ panel.layer.shadowColor/Offset/Radius set        │ SceneDelegate.swift:165-167                                                          │ F1       │ Shadow params from Theme                               │    
  ├──────────────────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────┼──────────┼────────────────────────────────────────────────────────┤ 
  │ panel.layer.shadowOpacity = 0 initial            │ SceneDelegate.swift:168                                                              │ F1       │ Starts at 0; curve drives during gesture               │    
  ├──────────────────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────┼──────────┼────────────────────────────────────────────────────────┤ 
  │ panel.layer.shadowPath updated in                │ SceneDelegate.swift:90-93                                                            │ F1       │ Allows shadow rendering on clipping layer; updates     │    
  │ viewDidLayoutSubviews                            │                                                                                      │          │ every frame as bounds change                           │
  ├──────────────────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────┼──────────┼────────────────────────────────────────────────────────┤    
  │ CAGradientLayer mask on pinkMask.layer           │ SceneDelegate.swift:135-143                                                          │ E3       │ Climbing pink reveal: location[0] controls boundary;   │    
  │                                                  │                                                                                      │          │ gradient stops are [black, transparent]                │
  ├──────────────────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────┼──────────┼────────────────────────────────────────────────────────┤    
  │ CAGradientLayer mask on greyMask.layer           │ SceneDelegate.swift:149-159                                                          │ E3       │ Climbing grey reveal: location[1] controls boundary;   │
  │                                                  │                                                                                      │          │ gradient stops are [transparent, black]                │    
  ├──────────────────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────┼──────────┼────────────────────────────────────────────────────────┤
  │ Pink mask gradient locations updated each frame  │ SceneDelegate.swift:278                                                              │ E3'      │ [topLoc, botLoc] = [pinkBoundary, pinkBoundary + 0.10] │    
  │                                                  │                                                                                      │          │  — transition-width 0.10 rides the boundary            │    
  ├──────────────────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────┼──────────┼────────────────────────────────────────────────────────┤
  │ Grey mask gradient locations updated each frame  │ SceneDelegate.swift:287                                                              │ E3'      │ [0.0, 1.0 - greyBoundary] — transparent zone grows     │    
  │                                                  │                                                                                      │          │ downward                                               │    
  ├──────────────────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────┼──────────┼────────────────────────────────────────────────────────┤
  │ CAGradientLayer mask on CSV (top-fade)           │ ChatBubbleStackView.swift:795-803                                                    │ A3       │ top-fade mask with [clear, black] stops; boundary at   │    
  │                                                  │                                                                                      │          │ locations[1]                                           │    
  ├──────────────────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────┼──────────┼────────────────────────────────────────────────────────┤
  │ top-fade mask locations updated each subscriber  │ ChatBubbleStackView.swift:870-875                                                    │ A3       │ [0.0, topFadeBoundary(p)]                              │    
  │ call                                             │                                                                                      │          │                                                        │    
  ├──────────────────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────┼──────────┼────────────────────────────────────────────────────────┤
  │ gradientView covers full view bounds             │ SceneDelegate.swift:192-195                                                          │ E1'      │ Page-gradient field                                    │    
  ├──────────────────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────┼──────────┼────────────────────────────────────────────────────────┤    
  │ Pink/grey/panel as siblings of gradientView in   │ SceneDelegate.swift:170-173                                                          │ E1+E3    │ Layered above gradient: gradient → pinkMask + greyMask │
  │ view                                             │                                                                                      │          │  → panel                                               │    
  ├──────────────────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────┼──────────┼────────────────────────────────────────────────────────┤    
  │ scaler (CSV) added to panel.addSubview           │ SceneDelegate.swift:174                                                              │ C1       │ Scaler inside panel; CSV is bottom-anchored within     │
  │                                                  │                                                                                      │          │ panel                                                  │    
  ├──────────────────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────┼──────────┼────────────────────────────────────────────────────────┤
  │ dormantBlur (UIVisualEffectView) as sibling of   │ ChatBubbleStackView.swift:817-819                                                    │ A6+A7    │ Blur effect view; full-size fills CSV; rides dissolve  │    
  │ scalingSurface in CSV                            │                                                                                      │          │ via dormantBlur.alpha                                  │    
  ├──────────────────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────┼──────────┼────────────────────────────────────────────────────────┤
  │ scalingSurface holds anchorPoint = (0.5, 1.0)    │ ChatBubbleStackView.swift:805                                                        │ A1       │ Bottom-anchored scale (anchor at bottom-middle of CSV) │    
  ├──────────────────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────┼──────────┼────────────────────────────────────────────────────────┤
  │ scalingSurface.layer.position manually set in    │ ChatBubbleStackView.swift:909-915                                                    │ A1       │ Frame/anchor reconciliation (auto-layout doesn't honor │    
  │ layoutSubviews                                   │                                                                                      │          │  non-default anchor reliably)                          │
  ├──────────────────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────┼──────────┼────────────────────────────────────────────────────────┤    
  │ bodyContent inside scalingSurface (rides         │ ChatBubbleStackView.swift:818                                                        │ A1       │ Bubble stack scales with surface                       │
  │ transform)                                       │                                                                                      │          │                                                        │    
  ├──────────────────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────┼──────────┼────────────────────────────────────────────────────────┤
  │ masksToBounds (panel.clipsToBounds=true) NOT     │ (preserved through F1)                                                               │ F1       │ F1 explicitly preserved this — shadow renders via      │    
  │ touched                                          │                                                                                      │          │ shadowPath, not via content-alpha                      │    
  └──────────────────────────────────────────────────┴──────────────────────────────────────────────────────────────────────────────────────┴──────────┴────────────────────────────────────────────────────────┘
                                                                                                                                                                                                                     
  1.5 — Subscriber/seam wiring                                                                                                                                                                                       
  
  Internal subscribers (ContentScalerView's init, ChatBubbleStackView.swift:855–897):                                                                                                                                
                                                            
  ┌─────┬────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┬─────────────────────────────────────────────────────────────┐
  │  #  │                                                        What it does                                                        │                           Target                            │                 
  ├─────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────┤
  │ 1   │ Compute s = scaleCurve(p), write scalingSurface.layer.transform = scale(s,s,1) inside CATransaction.withSuppressedActions  │ scalingSurface transform                                    │                 
  ├─────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────┤
  │ 2   │ Scrub blurAnimator.fractionComplete = blurCurve(p)                                                                         │ dormantBlur effect intensity                                │                 
  ├─────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────┤
  │ 3   │ Set top-fade mask locations = [0.0, topFadeBoundary(p)] inside suppressed actions                                          │ CSV layer mask                                              │                 
  ├─────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────┤                 
  │ 4   │ Compute a = contentDissolveAlpha(p), set bodyContent.alpha = a AND dormantBlur.alpha = a. CSV.alpha stays at 1.0 (neutral) │ bodyContent + dormantBlur (refactored from CSV.alpha in D1) │                 
  └─────┴────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┴─────────────────────────────────────────────────────────────┘                 
                                                                                                                                                                                                                     
  External subscribers (SandboxViewController.viewDidLoad, SceneDelegate.swift:239–312):
                                                                                                                                                                                                                     
  ┌─────┬─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┬──────────────────────────────────────┐
  │  #  │                                                                          What it does                                                                           │                Target                │   
  ├─────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼──────────────────────────────────────┤
  │ 1   │ Update debug readout text with p, scale, blurFraction                                                                                                           │ UILabel text                         │   
  ├─────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼──────────────────────────────────────┤
  │ 2   │ (Track B layout) Compute tH/tW, set panelWidth/Height/Bottom.constant; set pinkMask gradient locations to [pinkBoundary, pinkBoundary+0.10]; set greyMask       │ panel constraints + mask gradient    │   
  │     │ gradient locations to [0.0, 1.0-greyBoundary]                                                                                                                   │ layers                               │
  ├─────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼──────────────────────────────────────┤
  │ 3   │ (D1 label-in) Set scaler.dormantLabel.alpha = labelInAlpha(p)                                                                                                   │ dormantLabel.alpha                   │   
  ├─────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼──────────────────────────────────────┤   
  │ 4   │ (F1 shadow) Set panel.layer.shadowOpacity = Float(shadowOpacityCellRest * shadowOpacityCurve(p)) inside suppressed actions                                      │ panel.layer.shadowOpacity            │   
  └─────┴─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┴──────────────────────────────────────┘   
                                                                                                                                                                                                                     
  Total: 8 subscribers on the single scalingSurface.subscribe SSoT.
                                                                                                                                                                                                                     
  Dissolve refactor (D1): prior target was self.alpha (CSV.alpha). Current target is bodyContent.alpha + dormantBlur.alpha. CSV.alpha is never written — stays at default 1.0. The refactor's correctness banked
  against v23 end-of-A signature byte-identical comparison.                                                                                                                                                          
                                                            
  1.6 — Sweep harness state                                                                                                                                                                                          
                                                            
  - Current schedule (SceneDelegate.swift:317-328): 10-state demo schedule (p=0.00, 0.40, 0.44, 0.46, 0.48, 0.50, 0.52, 0.55, 0.60, 0.70 at fixed timestamps). Reverted post-F2.                                     
  - 101-step sweep harness (programmatically generated (0...100).map { ... }): previously installed for F1's whisper-test sweep and F2's measurement sweep. Currently NOT installed (reverted).
  - Sweep output directories on disk (candidate phantoms / build artifacts):
    - sweep_output/ — pre-F1 sweep (101 frames)                                                                                                                                                                      
    - sweep_f1/ — F1 sweep with opacity=0.12, radius=12
    - sweep_f1_final/ — F1 final params sweep (PRE-F2 baseline)                                                                                                                                                      
    - sweep_f2/ — POST-F2 sweep                                                                                                                                                                                      
    - /tmp/iter1_opacity008.png, /tmp/iter2_opacity006.png, /tmp/iter3_opacity004.png, /tmp/iter4_op006_r8.png — F1 dial-back iterations                                                                             
    - /tmp/ours_p100_crop.png, /tmp/ref_f060_crop.png, /tmp/cmp_* — whisper-test composites                                                                                                                          
    - These are build artifacts on disk, not in-code residue.                                                                                                                                                        
  - Reference video frames: _video_audit/f001.png through _video_audit/f060.png (60 frames at 788×1662 = @2x of 394×831 logical), present for reference comparison.                                                  
  - Surviving sweep code: none in source. The schedule-generator block (let states: [(Double, CGFloat, String)] = (0...100).map ...) is reverted. No flags, no comments, no schedule-state residue.                  
                                                                                                                                                                                                                     
  1.7 — Non-code artifacts (first-class inputs)                                                                                                                                                                      
                                                                                                                                                                                                                     
  Master spec/checklist (Part 1 nine-channel timeline, Part 2 items A1–F3, Part 3 tackle order): present in conversation history as the contract. Final status (post-F2 round):                                      
  - A1 (scale) ✅, A2 (history reveal) ✅, A3 (top-fade gradient) ✅, A4 (descending fade boundary + stagger) ✅, A5 (whole-content dissolve) ✅, A6 (blur onset) ✅, A7 (blur ramp) ✅, A8 (end-of-A character) ✅  
  - B1 (hold beat) ✅, B2 (keyboard dismiss) → INTEGRATION (deferred)                                                                                                                                                
  - C1 (aspect-changing contraction) ✅, C2 (bottom-anchored vertical-first) ✅, C3 (corner radius pre-rounded) ✅, C4 (placement) ✅ for sandbox slot (cellBottomLift=195), real slot → INTEGRATION; C5 (aspect     
  ~1.55) ✅, C6 (panelWidth eased shoulder) ✅                                                                                                                                                                  
  - D1 (body→label cross-fade) ✅, D2-mechanism ✅ (content → INTEGRATION), D3 (staggered label-in) ✅, D4 (sparkle) → INTEGRATION                                                                                   
  - E1 (gradient strength) ✅, E1' (gradient distribution) ✅, E2 (gradient throughout text phase) → RECLASSIFIED PRIMITIVE→INTEGRATION (emerges from bounded-surface architecture), E3 (climbing reveal) ✅, E3'
  (transition-width sharpening) ✅, E4 (edge contrast) ✅, E5 (panel fill) ✅                                                                                                                                        
  - F1 (shadow whisper) ✅, F2-texture ✅ (content → INTEGRATION), F3 (serif typography) → INTEGRATION                                                                                                               
                                                                                                                                                                                                                     
  Measured reference values (banked):                                                                                                                                                                                
                                                                                                                                                                                                                     
  ┌───────────────────────────────────────────────────────┬───────────────────────────────────────────────────────┬───────────────┬──────────────────────────────────────────────────────────────────────┐           
  │                      Measurement                      │                         Value                         │ Round closed  │                                Status                                │           
  ├───────────────────────────────────────────────────────┼───────────────────────────────────────────────────────┼───────────────┼──────────────────────────────────────────────────────────────────────┤
  │ Resting-fade alphas at y=40/60/100/120 (CSV-relative) │ 197/179/142/124                                       │ A3/A4         │ Methodology-shifted post-F2 (banked y-sampling is content-dependent) │           
  ├───────────────────────────────────────────────────────┼───────────────────────────────────────────────────────┼───────────────┼──────────────────────────────────────────────────────────────────────┤
  │ Cluster B5→B6 gap (top-fade)                          │ ≥0.10 (achieved 0.139)                                │ A4            │ ✓                                                                    │           
  ├───────────────────────────────────────────────────────┼───────────────────────────────────────────────────────┼───────────────┼──────────────────────────────────────────────────────────────────────┤
  │ End-of-A min                                          │ 225                                                   │ A5/A8         │ ✓ (bg-normalized percentile gate ±5)                                 │
  ├───────────────────────────────────────────────────────┼───────────────────────────────────────────────────────┼───────────────┼──────────────────────────────────────────────────────────────────────┤           
  │ v23 end-of-A signature (mean / p5 / dark-cov<227)     │ 232.1 / 226 / 5.8%                                    │ A5/A8         │ Re-banked PROVISIONAL post-F2 to 231.9 / 228.8 / 4.8%                │           
  ├───────────────────────────────────────────────────────┼───────────────────────────────────────────────────────┼───────────────┼──────────────────────────────────────────────────────────────────────┤           
  │ Reference body-clear at p=0.66 (mean / p5 / dark)     │ ≈233 / 233 / 1.1–2.1%                                 │ D1'           │ ✓ (scenario b, distinct from our v23 floor signature)                │           
  ├───────────────────────────────────────────────────────┼───────────────────────────────────────────────────────┼───────────────┼──────────────────────────────────────────────────────────────────────┤
  │ Reference pink saturation S                           │ ≈29 (NOT 71)                                          │ E1            │ ✓ (S=71 was THIS team's error, corrected)                            │           
  ├───────────────────────────────────────────────────────┼───────────────────────────────────────────────────────┼───────────────┼──────────────────────────────────────────────────────────────────────┤
  │ Pink vertical profile S                               │ 11 → 16 → 24 → 29                                     │ E1'           │ ✓                                                                    │           
  ├───────────────────────────────────────────────────────┼───────────────────────────────────────────────────────┼───────────────┼──────────────────────────────────────────────────────────────────────┤
  │ Reference cell-bottom position                        │ 77.1% of viewport                                     │ C4            │ ✓                                                                    │           
  ├───────────────────────────────────────────────────────┼───────────────────────────────────────────────────────┼───────────────┼──────────────────────────────────────────────────────────────────────┤
  │ Reference cell aspect                                 │ 1.55–1.60                                             │ C5            │ ✓ (build 1.549)                                                      │           
  ├───────────────────────────────────────────────────────┼───────────────────────────────────────────────────────┼───────────────┼──────────────────────────────────────────────────────────────────────┤
  │ Reference top-edge contrast delta                     │ ≈21 (build +18.57/+18.9)                              │ E5            │ ✓ (within tolerance)                                                 │           
  ├───────────────────────────────────────────────────────┼───────────────────────────────────────────────────────┼───────────────┼──────────────────────────────────────────────────────────────────────┤
  │ Reference pink-field extent                           │ 22.6% of viewport (build 22.8%)                       │ E3'           │ ✓                                                                    │           
  ├───────────────────────────────────────────────────────┼───────────────────────────────────────────────────────┼───────────────┼──────────────────────────────────────────────────────────────────────┤
  │ Reference body-clear→label-in stagger                 │ 0.20 of progress (generation-gated)                   │ D1'           │ ✓ (primitive uses 0.05 natural settle; integration extends to 0.86)  │           
  ├───────────────────────────────────────────────────────┼───────────────────────────────────────────────────────┼───────────────┼──────────────────────────────────────────────────────────────────────┤
  │ F1 shadow parameters (final)                          │ opacity 0.06, radius 8, offset (0,4), black           │ F1            │ ✓ (4 dial-back iterations)                                           │           
  ├───────────────────────────────────────────────────────┼───────────────────────────────────────────────────────┼───────────────┼──────────────────────────────────────────────────────────────────────┤
  │ Top-edge contrast at p=1.00                           │ +18.57 (PRE-F1 = PRE-F2 = POST-F2 all byte-identical) │ F1/F2         │ ✓                                                                    │           
  ├───────────────────────────────────────────────────────┼───────────────────────────────────────────────────────┼───────────────┼──────────────────────────────────────────────────────────────────────┤
  │ Resting CSV-region mean at p=0.00                     │ 222.28 (pre-F2) → 218.46 (post-F2 PROVISIONAL)        │ F2            │ re-banked PROVISIONAL                                                │           
  ├───────────────────────────────────────────────────────┼───────────────────────────────────────────────────────┼───────────────┼──────────────────────────────────────────────────────────────────────┤
  │ Recede phase per-step Δmean σ                         │ 0.301 (pre-F2) → 0.399 (post-F2)                      │ F2            │ finding banked (metadata-strip increased noise by 32%)               │           
  ├───────────────────────────────────────────────────────┼───────────────────────────────────────────────────────┼───────────────┼──────────────────────────────────────────────────────────────────────┤
  │ Holistic-sweep total dynamic range                    │ −16.4 (build) vs −15.1 (reference), within 9%         │ Holistic pass │ ✓                                                                    │           
  ├───────────────────────────────────────────────────────┼───────────────────────────────────────────────────────┼───────────────┼──────────────────────────────────────────────────────────────────────┤
  │ Hold beat per-step Δmean                              │ +0.007 (50× quieter than neighbors)                   │ Holistic pass │ ✓                                                                    │           
  └───────────────────────────────────────────────────────┴───────────────────────────────────────────────────────┴───────────────┴──────────────────────────────────────────────────────────────────────┘
                                                                                                                                                                                                                     
  Kink ledger (closed):                                     
                                                                                                                                                                                                                     
  ┌────────────────────────────────────────┬───────────────────────────────────────────────┬───────────────────────────────┬────────────────────────────────────────────────────────────────────────────────────┐ 
  │                Channel                 │                 Original kink                 │         Closure round         │                                       Status                                       │    
  ├────────────────────────────────────────┼───────────────────────────────────────────────┼───────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────┤ 
  │ panelHeightCurve @ p=0.50              │ onset velocity discontinuity                  │ B1                            │ ✓ Hermite shoulder [0.50, 0.55]                                                    │    
  ├────────────────────────────────────────┼───────────────────────────────────────────────┼───────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────┤ 
  │ pinkMaskAlpha @ p=0.50                 │ onset velocity discontinuity                  │ B1'                           │ ✓ matched-span shoulder co-onset with panelContraction                             │    
  ├────────────────────────────────────────┼───────────────────────────────────────────────┼───────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────┤ 
  │ pinkMaskAlpha @ p=0.65                 │ end velocity discontinuity                    │ B1'                           │ ✓ symmetric end shoulder [0.60, 0.65] (closed when fixing onset — "finish the      │ 
  │                                        │                                               │                               │ channel you're in" principle)                                                      │    
  ├────────────────────────────────────────┼───────────────────────────────────────────────┼───────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────┤    
  │ panelWidthCurve @ p=0.62               │ onset velocity discontinuity                  │ C6                            │ ✓ Hermite shoulder [0.62, 0.67]                                                    │    
  ├────────────────────────────────────────┼───────────────────────────────────────────────┼───────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────┤    
  │ greyMaskAlpha @ p=0.54 (onset, moved   │ onset velocity discontinuity                  │ E3                            │ ✓ Hermite shoulder [0.54, 0.59]                                                    │ 
  │ from 0.75)                             │                                               │                               │                                                                                    │    
  ├────────────────────────────────────────┼───────────────────────────────────────────────┼───────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────┤ 
  │ greyMaskAlpha @ p=0.90                 │ end velocity discontinuity                    │ E3                            │ ✓ Hermite end shoulder [0.85, 0.90]                                                │    
  ├────────────────────────────────────────┼───────────────────────────────────────────────┼───────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────┤
  │ topFadeBoundary math-kink @ p=0.50     │ declared BENIGN (output clamped at 1.0; no    │ recorded in B1' principle     │ ✓ benign                                                                           │    
  │                                        │ visible motion)                               │                               │                                                                                    │
  ├────────────────────────────────────────┼───────────────────────────────────────────────┼───────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────┤    
  │ scaleCurve @ p=0.12 and p=0.45         │ linear curve with velocity kinks at           │ NOT closed (A1 closed without │ ⚠️  OPEN — non-C¹ active curve; principle (b) partially violated                    │
  │                                        │ boundaries                                    │  easing)                      │                                                                                    │    
  └────────────────────────────────────────┴───────────────────────────────────────────────┴───────────────────────────────┴────────────────────────────────────────────────────────────────────────────────────┘

  Deferred-to-integration list (final state):                                                                                                                                                                        
  
  ┌─────────────────────────────────────┬────────────────────────────────────────────────────────────────────────────────────┬───────────────────────────────────────────────────────────────────────────────────┐   
  │                Item                 │                                 Stand-in / status                                  │                                  Real mechanism                                   │
  ├─────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────┼───────────────────────────────────────────────────────────────────────────────────┤
  │ D2-content                          │ Placeholder summary text "Good morning check-in, daily exercise nudge, 20-minute   │ Real curated summary text from data pipeline                                      │   
  │                                     │ workout suggestions"                                                               │                                                                                   │
  ├─────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────┼───────────────────────────────────────────────────────────────────────────────────┤   
  │ D4 (sparkle/generating glyph)       │ Not present                                                                        │ Real-data artifact; fills the 0.20 generation-gated stagger window                │
  ├─────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────┼───────────────────────────────────────────────────────────────────────────────────┤
  │ C4 real slot                        │ cellBottomLift=195 (sandbox stand-in for low-slot in real list)                    │ Real list provides per-cell slot                                                  │   
  ├─────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────┼───────────────────────────────────────────────────────────────────────────────────┤   
  │ F3 (serif typography)               │ dormantLabel uses .systemFont override in sandbox                                  │ Real label uses Theme.Typography.destinationDate (.serif design)                  │   
  ├─────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────┼───────────────────────────────────────────────────────────────────────────────────┤   
  │ B2 (keyboard dismiss)               │ Not present (no keyboard in sandbox)                                               │ Real composer keyboard dismiss fills the hold beat (0.44–0.50)                    │
  ├─────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────┼───────────────────────────────────────────────────────────────────────────────────┤   
  │ E2 (gradient throughout text phase) │ Cannot be built in sandbox without panel.alpha<1 (would break dissolve-floor +     │ Emerges from real bounded chat surface (composer/keyboard area exposes field)     │
  │                                     │ cluster-hold) or restructuring a replaced node                                     │                                                                                   │   
  ├─────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────┼───────────────────────────────────────────────────────────────────────────────────┤
  │ F2-content (real conversation       │ metadataHidden=true on dummy bubbles                                               │ Real ChatBubbleView (default metadataHidden=false) — F2 banked spec:              │   
  │ rendering)                          │                                                                                    │ paragraph-style flow, NOT metadata-strip alone                                    │
  ├─────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────┼───────────────────────────────────────────────────────────────────────────────────┤   
  │ Role-signaling mechanism            │ Spacing-based grouping (4pt same / 16pt different)                                 │ Real renderer design decision (alignment / color / single-direction / grouping)   │
  ├─────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────┼───────────────────────────────────────────────────────────────────────────────────┤   
  │ F1.5 (panel-edge softening during   │ Not present                                                                        │ Observed in reference (uniform soft halo on card edges at p~0.55–0.78);           │
  │ contraction)                        │                                                                                    │ provisional proto-spec                                                            │   
  ├─────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────┼───────────────────────────────────────────────────────────────────────────────────┤   
  │ Punch-list (methodology, not        │                                                                                    │                                                                                   │
  │ regression)                         │                                                                                    │                                                                                   │   
  ├─────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────┼───────────────────────────────────────────────────────────────────────────────────┤
  │ Top-fade y-sampling protocol        │ Banked y=40/60/100/120 → 197/179/142/124 spec depends on chat-bubble content       │ Re-derive against curve outputs / explicit crop bounds                            │   
  │                                     │ positions                                                                          │                                                                                   │   
  ├─────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────┼───────────────────────────────────────────────────────────────────────────────────┤
  │ p=0.46 end-of-A p5/dark sampling    │ Sampling-window dependent; mean matches but p5/dark drift                          │ Re-bank with explicit crop bounds at integration                                  │   
  └─────────────────────────────────────┴────────────────────────────────────────────────────────────────────────────────────┴───────────────────────────────────────────────────────────────────────────────────┘   
                                          
  Standing principles (15, labeled a–o):                                                                                                                                                                             
                                                                                                                                                                                                                     
  ┌───────┬─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
  │ Label │                                                                                          Principle                                                                                          │            
  ├───────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ (a)   │ Gesture as nine concurrent curves with measured onsets/rates/crossings, not a sequence of states                                                                                            │            
  ├───────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ (b)   │ Interactive curves are pure / monotonic / smooth(C¹) functions of p — emphasis via velocity, never stops or kinks                                                                           │
  ├───────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ (c)   │ A velocity kink only matters where output is actively moving (clamped/saturated kinks benign)                                                                                               │
  ├───────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤            
  │ (d)   │ Co-onset asymmetry fix is matched velocity profiles (matched-span shoulders), not independent kink-removal                                                                                  │            
  ├───────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤            
  │ (e)   │ Fritsch-Carlson monotone Hermite tangents (no overshoot)                                                                                                                                    │            
  ├───────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ (f)   │ Measure-not-guess against reference                                                                                                                                                         │            
  ├───────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ (g)   │ Calibrated metrics — when min/mean disagree, diagnose the measurement                                                                                                                       │            
  ├───────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ (h)   │ Bg-normalized comparison when backgrounds differ                                                                                                                                            │            
  ├───────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ (i)   │ Primitive-vs-integration filter (mechanism/choreography primitive; content/real-classes integration)                                                                                        │
  ├───────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ (j)   │ Decline "deferred-to-architecture" attributions on analytic prediction alone — test the in-scope tunable first                                                                              │            
  ├───────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ (k)   │ Fix placement before tuning dependent variables (C4 before gradient stops; cell position before mask transition)                                                                            │            
  ├───────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ (l)   │ Programmatic sweep removes hand-velocity confounds at seams                                                                                                                                 │            
  ├───────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ (m)   │ "Finish the channel you're in" when fixing one of its kinks                                                                                                                                 │            
  ├───────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ (n)   │ Verification-context (sim / methodology / crop / bounds) is part of the closed bank                                                                                                         │            
  ├───────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ (o)   │ The primitive must never become the source of truth — real components are authority on data/content/layout/navigation/accessibility/typography, primitive is authority on choreography only │            
  └───────┴─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
                                                                                                                                                                                                                     
  F2/E2 closure decisions (final round):                    
                                                                                                                                                                                                                     
  - metadataHidden reversible flag (default-false, accessibility untouched, real renderer unaffected)
  - Spacing-based grouping (4pt same-role / 16pt role-transition)                                                                                                                                                    
  - F2 finding (banked): texture cleanliness depends on BOTH metadata-noise AND body-content density — metadata-strip alone increased recede Δmean σ by 32%, so the real-renderer spec is long-form / paragraph-style
   flow                                                                                                                                                                                                              
  - E2 reclassified PRIMITIVE → INTEGRATION (sandbox attempt would require panel.alpha<1, breaking closed dissolve-floor landing and cluster-hold signature, or restructuring a replaced node)
  - Load-bearing gates re-banked as PROVISIONAL pending real-content re-derivation                                                                                                                                   
                                                                                                                                                                                                                     
  1.8 — Four handoff/crossing points (structural facts)                                                                                                                                                              
                                                                                                                                                                                                                     
  1. Top-fade leads scale (early): top-fade boundary present at rest (y=0.10 at p=0) → already-engaged when scale onset fires at p=0.12. They run concurrently early.                                                
  2. Reveal locks ~0.33 before blur starts ~0.40: history-reveal lock (when scale floors) closes at p=0.33 (scaleCurve hits scaleAtCellRest at 0.45 but reveal-lock is informally at 0.33 per master spec). Blur     
  onset is at p=0.40. There's a gap p=[0.33, 0.40] of small-but-sharp text.                                                                                                                                          
  3. Blur is the LAST Track-A act (0.40–0.44), after scale completes and reveal locks; fade+blur crash together into the dissolve: blur peaks at p=0.44, dissolve onset is p=0.42, dissolveFullP is 0.46. Composite  
  end-of-A is faint+soft.                     
  4. Hold beat 0.44–0.50, then eased contraction onset at 0.50; label resolving 0.85–1.0 (de-gated for primitive, integration extends label-in to ~0.86 with sparkle): the breath between Track A and Track B. Panel 
  bounds bit-identical through p=0.50. After contraction begins (matched-shoulder co-onset with pinkMask), the back half runs to settle.
                                                                                                                                                                                                                     
  1.9 — Verified-closed state per channel with verification context
                                                                                                                                                                                                                     
  ┌────────────────────┬─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐ 
  │      Channel       │                                                                  Verification (what / where / gate / what invalidates)                                                                  │   
  ├────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤ 
  │                    │ Cluster-then-hold curve verified via dense band-profile sweep against reference's resting alpha profile (y=40/60/100/120 → 197/179/142/124). Sampling: CSV-relative y, center column.   │   
  │ Top-fade           │ Gate: ±2 lum at each y. Invalidator: chat content layout shift (F2 changed bubble layout — methodology punch-listed, not closed-state regression). Sim: iOS 18 / iPhone 16, UDID        │ 
  │                    │ C149C833-D1F6-4187-A202-89B2073D98A9.                                                                                                                                                   │   
  ├────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤ 
  │ Scale              │ Visual confirmation that text gets small by p~0.33–0.40 with similarity transform. Sampling: visual frame comparison. Gate: smooth velocity from p=0.12 to scaleAtCellRest=0.40 by      │ 
  │                    │ p=0.45. Open: velocity kinks at boundaries (linear curve).                                                                                                                              │   
  ├────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤ 
  │ Reveal             │ History reveal lock verified at scaleFullP=0.45 (informally at 0.33 per master spec). Mechanism: scale-anchored bottom (recent message holds at bottom; older messages descend).        │   
  ├────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤   
  │ Blur               │ 5-knot Hermite verified via reference's sharpness 220→8 in two frames at p=0.40→0.42; our crash at p=0.40→0.44. Gate: blurMaxFraction joint-calibrated with dissolveFloor for composite │ 
  │                    │  end-state ~225 mean. Invalidator: changing either blurMaxFraction or dissolveFloor independently.                                                                                      │   
  ├────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤   
  │ Dissolve           │ End-of-A signature at p=0.46: banked v23 (PRE-F2) mean=232.1, p5=226, dark=5.8%; PROVISIONAL POST-F2 mean=231.9, p5=228.8, dark=4.8%. Sampling: panel-interior with 20pt/30pt insets.   │ 
  │                    │ Gate: ±3 lum.                                                                                                                                                                           │   
  ├────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤ 
  │ Hold beat          │ Per-step Δmean in panel-interior [0.46, 0.50] = +0.007 (50× quieter than recede/contract). Verified via holistic 101-step sweep. Sampling: panel-interior signature. Gate: per-step     │   
  ├────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤   
  │ Panel contraction  │ Hermite shoulder [0.50, 0.55] + linear to 1.0. Verified visually at p=0.66 (panel ~76% screen), p=1.00 (cell-rest at 226×350pt). Sampling: panel bbox via brightness threshold +        │
  │ (height)           │ computed via curve formula. Gate: panel.bot at y=77.1% of viewport at p=1.0.                                                                                                            │   
  ├────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤   
  │ Panel contraction  │ Hermite shoulder [0.62, 0.67] + linear. Verified at p=0.66 (panel ~388.65pt wide), p=1.00 (350pt = cellWidth).                                                                          │
  │ (width)            │                                                                                                                                                                                         │   
  ├────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤   
  │ Pink reveal        │ Matched-span shoulders [0.50, 0.55, 0.60, 0.65] verified via programmatic sweep at p=0.50–0.65. Reference: pink visible in bottom 22.6% of viewport; build: 22.5% (within 0.1pp).       │
  │                    │ Sampling: pink-band mean at y=85–95% of viewport.                                                                                                                                       │   
  ├────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ Grey reveal        │ Shoulders [0.54, 0.59, 0.85, 0.90] verified against reference's grey-at-top reveal climbing down. Sampling: grey-band mean at y=80–160px.                                               │   
  ├────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤   
  │ Body-out +         │ Body fully cleared at p=0.66 (panel-interior mean = 234.77, dark=0%, byte-identical reference signature). Label visible at p=0.78 (mean drops 234.77→232.40 in panel-interior). 0.05    │
  │ label-in           │ empty-card beat between. Sampling: panel-interior signature; pre/post-F2 byte-identical at these p's.                                                                                   │   
  │ cross-fade         │                                                                                                                                                                                         │   
  ├────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ Shadow             │ 4-iteration whisper test against reference f060 cropped tight to bottom card. Final params 0.06/r8/(0,4). Top-edge contrast at p=1.0 byte-identical pre-F1/post-F1/post-F2 = +18.57.    │   
  │                    │ Sampling: side-by-side perceptual judgment (subjective, not pixel-match).                                                                                                               │
  ├────────────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤   
  │ Holistic composite │ 101-step sweep at p=0.00→1.00, full visual continuity confirmed. Total dynamic range −16.4 (build) vs −15.1 (reference) = within 9%. No Δmean spike at any documented co-onset.         │
  └────────────────────┴─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘   
                                          
  Sim/OS for ALL verifications: iOS 18.0 / iPhone 16 simulator, UDID C149C833-D1F6-4187-A202-89B2073D98A9. Frames captured at 1179×2556 (@3x of 393×852 logical). Reference frames at 788×1662 (@2x of 394×831       
  logical).                                                                                                                                                                                                          
  
  ---                                                                                                                                                                                                                
  STEP 2 — Wave 1 Root Interrogation (six questions on the primitive as a whole)
                                                                                                                                                                                                                     
  ROOT NODE: The sandbox pinch primitive as a complete now-closed body of work — all curves, constants, view-hierarchy, subscribers, verification protocol, master spec, and the F2/E2 closure decisions.
                                              
  Q1 — What does this REST ON? (Structural / conceptual / environmental dependencies)                                                                                                                                
                                          
  - ScalingSurface p-driver SSoT (subscribe/setProgress pattern) — the single point all 8 subscribers depend on. HOT / KEYSTONE.                                                                                     
  - The reference video (60 frames in _video_audit/) as ground truth for every measured value.                                                                                                                       
  - iOS 18 / iPhone 16 simulator as the verification environment. All visual measurements bound to this sim.                                                                                                         
  - UIKit's CAGradientLayer mask + CABasicAnimation-free philosophy (curves drive layer properties inside CATransaction.withSuppressedActions).                                                                      
  - UIViewPropertyAnimator scrubbing trick (paused animator, fractionComplete writes scrub blur intensity) — only public API for continuous blur.
  - Theme.Page.surface as the panel fill — "page locally lifted" perceptual model (E5).                                                                                                                              
  - The dummy conversation's specific content/density — banked perceptual values are tied to this content.                                                                                                           
  - The CSV's full-screen frame — top-fade mask coords assume CSV is screen-height.                                                                                                                                  
  - The full-screen panel architecture — gradient is hidden BEHIND opaque panel during chat phase; E2 reclassification rests on this being a sandbox-specific rendering model.                                       
  - Cubic Hermite (Fritsch-Carlson) mathematics — foundational technique used in topFadeBoundary and blurCurve; the eased shoulders elsewhere use cubic Hermite variants.                                            
  - The "primitive must never become the source of truth" discipline (principle o) — the entire trace's framing rests on this.                                                                                       
                                                                                                                                                                                                                     
  Q2 — WHY does this exist? (Causal/historical origin)                                                                                                                                                               
                                                                                                                                                                                                                     
  - The reference video showed a gesture that didn't read as a sequence of states — it read as a CONTINUOUS transformation. The primitive exists to prove the choreography can be built as nine concurrent curves    
  with measured onsets/rates/crossings. The principle (a) was the foundational decision.                                                                                                                             
  - The earlier build collapsed Track A onto a single early point (~0.30–0.45) with no hold and started contraction at 0.45. The primitive was rebuilt to honor the reference's actual timing (the four              
  handoff/crossing points), with measured corrections at each round.                                                                                                                                                 
  - The sandbox was created to isolate the choreography from the real app's complexity (navigation, real data, real cells, keyboard, etc.) so the primitive can be tuned without integration noise.
  - Specific tuned constants exist because measured reference values demanded them — every round listed in 1.2 has a measured value as its WHY.                                                                      
                                                                                                                                                                                                                     
  Q3 — What ASSUMPTIONS does this encode? (Epistemological substrate — most important)
                                                                                                                                                                                                                     
  Environmental assumptions:                                                                                                                                                                                         
  - iPhone 16 / iOS 18 simulator pixel dimensions and rendering pipeline                                                                                                                                             
  - 60fps reference video frames map to our 101-step p sweep via prior calibration (f40 ≈ p=0.66, f52 ≈ p=0.86)                                                                                                      
  - The dummy conversation's specific content+density (banked perceptual values are tied to this)                                                                                                                    
  - No keyboard, no navigation, no other cells (sandbox isolation)                               
  - The scrub-and-measure verification loop (programmatic sweep with screenshot capture, principle l) faithfully reproduces the perceptual reading                                                                   
                                              
  Architectural assumptions:                                                                                                                                                                                         
  - The single-p-driver pattern scales to any number of subscribers (current 8) without coordination bugs
  - CATransaction.withSuppressedActions blocks implicit Core Animation animations for every layer-property mutation                                                                                                  
  - viewDidLayoutSubviews fires for every panel-bound change (it does, because the constraints are mutated)                                                                                                          
  - setCustomSpacing on UIStackView is honored deterministically (it is)                                                                                                                                             
  - The panel's clipsToBounds=true + shadowPath pattern paints shadow correctly on iOS 18 (validated in F1)                                                                                                          
                                                                                                           
  Methodological assumptions:                                                                                                                                                                                        
  - Mean luminance + p5 + dark-coverage is a sufficient perceptual signature for closing channels                                                                                                                    
  - Side-by-side visual whisper test (subjective) is the right termination for shadow tuning                                                                                                                         
  - Byte-identical PRE vs POST sweep comparison validates "no disturbance to closed channels"                                                                                                                        
  - The 4-criteria mechanical-drift gate is correct policy                                                                                                                                                           
  - Measurement-against-reference is correct ground-truth (principle f) — but reference may be compositionally different (different keyboard, different content, phone bezel)                                        
                                                                                                                                                                                                                     
  Content-model assumptions:                                                                                                                                                                                         
  - The dummy conversation's "Good morning..." final message stands in for a real summary                                                                                                                            
  - The role labels + timestamps in standard ChatBubbleView are the "noise" F2 strips — assumption: the noise was the metadata, NOT the body density (F2 finding falsified this; body density also matters)          
                                                                                                                                                                                                                     
  Timing assumptions:                                                                                                                                                                                                
  - The 0.05 empty-card beat (between body-clear at 0.66 and label-in at 0.71) is the primitive's de-gated stand-in for the reference's 0.20 generation-gated stagger. Assumes the integration sparkle/generation    
  will fill the larger window.                                                                                                                                                                                       
  - Hold beat duration of 0.04 p-progress (≈60ms wall time at 1.5s gesture) is "long enough" for the breath to register                                                                                              
                                                                                                                                                                                                                     
  Verification-context assumptions:                                                                                                                                                                                  
  - Sim renders identically to production hardware (no investigated divergence)                                                                                                                                      
  - Reference video's recording sim/hardware matches our verification sim (unknown; reference recording context unspecified)                                                                                         
                                                                                                                                                                                                                     
  Q4 — What would happen if this CHANGED? (Forward propagation)
                                                                                                                                                                                                                     
  If the p-driver pattern changed (e.g., introduced multi-driver, dependency-graph timing, async): every subscriber path breaks; all curves' purity-of-p invariant breaks; reverse-pinch retracing breaks.
                                                                                                                                                                                                                     
  If the reference video changed: every banked measurement invalidates; rounds reopen.                                                                                                                               
                                                                                                                                                                                                                     
  If the dummy conversation content changed: F2-finding's premise (long-form/paragraph-style) needs re-verification; PROVISIONAL banks need re-derivation; resting CSV mean shifts.                                  
                                                                                                                                                                                                                     
  If the sandbox screen size changed (different sim): topFadeBoundary's CSV-relative y-sampling shifts; cellBottomLift's stand-in slot becomes misaligned; gradient stops' percentage-of-viewport positions become
  inconsistent.                                                                                                                                                                                                      
                                                            
  If the Theme.Page.surface color shifted: panel fill ≠ gradient surface stop; E5 ("panel = bright band = page locally lifted") breaks; mask backgrounds also shift.                                                 
                                                            
  If C4 cellBottomLift=195 changed to a different stand-in slot: gradient locations [0.50, 0.55, 0.85] re-tune; cell.top vs gradient grey transition contrast shifts; the +18.57 banked edge contrast invalidates.   
                                                                                                                                                                                                                     
  Q5 — What would happen if this were REMOVED? (Concrete behavioral walkthrough)
                                                                                                                                                                                                                     
  If the entire primitive were removed: the sandbox app shows nothing. The real app still works (V2RootViewController is the production root). The choreography knowledge banked in conversation history + this Atlas
   remains.                                                                                                                                                                                                          
                                                            
  If the ScalingSurface SSoT were removed: every subscriber path collapses; setProgress has nowhere to write; nothing animates.                                                                                      
                                                            
  If the dissolve curve were removed: end-of-A would be full-contrast not faint; visible Track A end-state breaks; integration-handed-off cell carries unfaded chat content.                                         
                                                                                                                                                                                                                     
  If the hold beat were removed (panelContractionOnset → 0.46): the breath disappears; eye-settled-on-still-then-eruption-of-motion read collapses to a "no pause, direct motion" feel; reference fidelity drops.
                                                                                                                                                                                                                     
  If the shadow were removed: card edge less grounded; perceptual cell-rest reads as flatter; integration cells inherit this absence (mitigated by F1 finding banked).
                                                                                                                                                                                                                     
  If the F2 metadataHidden flag were removed: dummy bubbles regain role+timestamp labels; PROVISIONAL banks invalidate; recede reads with more metadata noise. Reversible by design.
                                                                                                                                                                                                                     
  Q6 — What's ABSENT? (Negative space — actively hunt)      
                                                                                                                                                                                                                     
  ┌────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┬─────────────────────────────────────────────────┐
  │                                                                       Absent feature                                                                       │                      Class                      │   
  ├────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────┤
  │ Cancel-before-threshold behavior (finger released mid-arc — commit or snap back?)                                                                          │ latent-risk / integration-required              │   
  ├────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────┤
  │ Velocity-based commitment thresholds (pinch velocity decides commit direction)                                                                             │ integration-required                            │
  ├────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────┤
  │ Full reverse-pinch verification at forward-rigor — only partial done (curves are pure functions of p, so reverse trivially retraces by construction, but   │ latent-risk                                     │
  │ no programmatic reverse-direction sweep with measured perceptual targets)                                                                                  │                                                 │   
  ├────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────┤   
  │ Multi-touch / interruption handling (second finger, pause-and-resume, hand-off)                                                                            │ integration-required                            │   
  ├────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────┤   
  │ State restoration (mid-gesture backgrounding, foreground resume)                                                                                           │ integration-required                            │
  ├────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────┤   
  │ Accessibility — reduced motion (UIAccessibility.isReduceMotionEnabled), VoiceOver gesture semantics, Dynamic Type, color/contrast accommodations           │ integration-required (deprioritized per user    │
  │                                                                                                                                                            │ memory but still required at integration)       │   
  ├────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────┤
  │ Orientation/rotation during gesture (the constants assume portrait at iPhone 16 pixel-perfect)                                                             │ integration-required                            │   
  ├────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────┤
  │ Safe-area / Dynamic-type / device-size scaling — constants hardcoded for iPhone 16 (393×852)                                                               │ integration-required                            │   
  ├────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────┤
  │ Keyboard appear/dismiss during gesture — explicitly deferred (B2)                                                                                          │ integration-required                            │   
  ├────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────┤
  │ Backgrounding mid-gesture — UIScene.willDeactivateNotification handling                                                                                    │ integration-required                            │   
  ├────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────┤
  │ The 4 closed channels' curves use 3 different easing strategies (linear+clamp for scale; smoothstep for dissolve/label-in/shadow; Fritsch-Carlson Hermite  │                                                 │   
  │ for top-fade/blur; matched Hermite for masks). Absent: a unifying "every active curve uses Hermite shoulders" pass. ScaleCurve remains the lone non-C¹     │ latent-risk (principle b partial violation)     │
  │ active curve.                                                                                                                                              │                                                 │   
  ├────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────┤
  │ Reverse-pinch sparkle behavior — what happens during reverse direction at p=0.86 ↔ p=0.66? (sparkle should presumably reverse)                             │ integration-required (D4)                       │   
  ├────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────┤
  │ Tap-to-chat reverse direction (cell → chat at p=1 → p=0) — this primitive defines forward direction; reverse is "trivially handled by pure-of-p" but no    │ latent-risk                                     │   
  │ scoped verification                                                                                                                                        │                                                 │
  ├────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────┤   
  │ F1.5 panel-edge softening during contraction — observed in reference, banked as proto-spec, not built                                                      │ latent-risk / integration-required              │
  ├────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────┤   
  │ The "p reaches 1.0" terminal action — what happens AFTER cell-rest? Real app would navigate to cell-list; sandbox just holds                               │ integration-required                            │
  ├────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────┤   
  │ Touch-up commitment animation — when user releases pinch, no spring-to-nearest-state or velocity-based commit; sandbox just freezes at last p              │ integration-required                            │   
  └────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┴─────────────────────────────────────────────────┘
                                                                                                                                                                                                                     
  ---                                                       
  STEP 4 — Wave 1 Dispatch Map (heat-classified branches)                                                                                                                                                            
                                                            
  Based on the root interrogation, first-level branches from the primitive root:                                                                                                                                     
                                                            
  ┌─────┬────────────────────────────────────────────────────────────────────────────────────────┬───────────────┬───────────────────────────────────────────────────────────────────────────────────────────────┐   
  │  #  │                                         Branch                                         │     Heat      │                                    Files agents will need                                     │
  ├─────┼────────────────────────────────────────────────────────────────────────────────────────┼───────────────┼───────────────────────────────────────────────────────────────────────────────────────────────┤   
  │ 1   │ p-driver SSoT + subscriber seam + pure-function-of-p invariant                         │ HOT           │ ChatBubbleStackView.swift (ScalingSurface + ContentScalerView init), SceneDelegate.swift      │   
  │     │                                                                                        │ (KEYSTONE)    │ (external subscribers)                                                                        │
  ├─────┼────────────────────────────────────────────────────────────────────────────────────────┼───────────────┼───────────────────────────────────────────────────────────────────────────────────────────────┤   
  │ 2   │ Track A: top-fade + scale + reveal + blur + dissolve as choreography with crossing     │ HOT           │ ChatBubbleStackView.swift (curves + subscribers)                                              │
  │     │ points                                                                                 │               │                                                                                               │
  ├─────┼────────────────────────────────────────────────────────────────────────────────────────┼───────────────┼───────────────────────────────────────────────────────────────────────────────────────────────┤   
  │ 3   │ Hold beat + dissolveFloor calibration + the breath                                     │ HOT           │ ChatBubbleStackView.swift (panelContractionOnsetP, dissolveFloor), the holistic-sweep data    │   
  ├─────┼────────────────────────────────────────────────────────────────────────────────────────┼───────────────┼───────────────────────────────────────────────────────────────────────────────────────────────┤   
  │ 4   │ Track B contraction: panelHeight + panelWidth, matched Hermite shoulders, kink ledger  │ HOT           │ ChatBubbleStackView.swift (curves), SceneDelegate.swift (constraint updates)                  │   
  │     │ closures                                                                               │               │                                                                                               │
  ├─────┼────────────────────────────────────────────────────────────────────────────────────────┼───────────────┼───────────────────────────────────────────────────────────────────────────────────────────────┤   
  │ 5   │ Gradient field: pinkMask + greyMask + reveal + Theme stops + transitionWidth + C4      │ HOT           │ SceneDelegate.swift, Theme.swift, ChatBubbleStackView.swift (mask curves)                     │
  ├─────┼────────────────────────────────────────────────────────────────────────────────────────┼───────────────┼───────────────────────────────────────────────────────────────────────────────────────────────┤
  │ 6   │ Body→label cross-fade: bodyOut + empty-card beat + labelIn + dormantLabel reparenting  │ HOT           │ ChatBubbleStackView.swift (curves), SceneDelegate.swift (reparenting + constraints)           │
  ├─────┼────────────────────────────────────────────────────────────────────────────────────────┼───────────────┼───────────────────────────────────────────────────────────────────────────────────────────────┤
  │ 7   │ F1 shadow + F2 texture (the final-round closures + reclassification of E2)             │ HOT           │ SceneDelegate.swift, Theme.swift, ChatBubbleView.swift, ChatBubbleStackView.swift             │
  ├─────┼────────────────────────────────────────────────────────────────────────────────────────┼───────────────┼───────────────────────────────────────────────────────────────────────────────────────────────┤
  │ 8   │ View hierarchy + composition: CSV/scaler/panel/masks/dormantLabel/gradient/shadow-path │ HOT           │ SceneDelegate.swift, ChatBubbleStackView.swift                                                │
  ├─────┼────────────────────────────────────────────────────────────────────────────────────────┼───────────────┼───────────────────────────────────────────────────────────────────────────────────────────────┤
  │ 9   │ Verification methodology + banked values + holistic sweep + regression gates           │ HOT           │ conversation history (banked values), sweep_output/, sweep_f1_final/, sweep_f2/               │
  ├─────┼────────────────────────────────────────────────────────────────────────────────────────┼───────────────┼───────────────────────────────────────────────────────────────────────────────────────────────┤
  │ 10  │ Standing principles (a-o) + how they propagated through rounds                         │ HOT           │ conversation history (principles)                                                             │
  ├─────┼────────────────────────────────────────────────────────────────────────────────────────┼───────────────┼───────────────────────────────────────────────────────────────────────────────────────────────┤
  ├─────┼────────────────────────────────────────────────────────────────────────────────────────┼───────────────┼───────────────────────────────────────────────────────────────────────────────────────────────┤
  │ 11  │ Deferred-to-integration list + the primitive/integration boundary                      │ HOT           │ conversation history (deferral decisions), code (where stand-ins live)                        │
  ├─────┼────────────────────────────────────────────────────────────────────────────────────────┼───────────────┼───────────────────────────────────────────────────────────────────────────────────────────────┤
  │ 12  │ Kink ledger + master spec/checklist (the contract)                                     │ WARM          │ conversation history                                                                          │
  └─────┴────────────────────────────────────────────────────────────────────────────────────────┴───────────────┴───────────────────────────────────────────────────────────────────────────────────────────────┘

  Dispatch decision: 11 HOT branch agents (opus), 1 WARM consolidated agent (sonnet), all in parallel via Agent tool with run_in_background: true. Each agent traces its branch to bedrock/critical/frontier/cycle at
   every leaf, applies the six questions at every node, applies Lens A/B/C/D/E/F where relevant, hunts for phantoms.

  ---
  Wave 2 — Dispatching parallel branch-tracing agents

⏺ 12 background agents launched (↓ to manage)
   ├ Trace: p-driver SSoT + subscriber seam
   ├ Trace: Track A channels + crossing points
   ├ Trace: hold beat + dissolve floor
   ├ Trace: Track B contraction + kink closures
   ├ Trace: gradient field + pink/grey masks
   ├ Trace: body→label cross-fade
   ├ Trace: F1 shadow + F2 texture closures
   ├ Trace: view hierarchy + composition
   ├ Trace: verification methodology + banked values
   ├ Trace: standing principles + epistemology
   ├ Trace: deferred-to-integration list
   └ Trace warm branches

⏺ All 12 Wave 2 agents dispatched in background — 11 HOT branch agents (opus) + 1 WARM consolidated agent (sonnet). Hook-safety review confirms safe parallel dispatch: every agent is read-only (no write conflicts
  possible), each prompt is fully self-contained with working directory, root context, branch scope, the six questions, terminal types, classifications, counterfactuals, files to read, and output format. Output of
   Wave 2 is required input to Wave 3 (synthesis) and Wave 4 (metacognitive), so I correctly wait for completion notifications rather than poll.
                                          
⏺ Agent "Trace: view hierarchy + composition" completed
                                                                                                                                                                                                                     
⏺ Wave 2 agent #8 (view hierarchy + composition) has returned. Key findings captured for synthesis:
                                                                                                                                                                                                                     
  Phantom findings (clean, but with fragility):                        
  - D1 dormantLabel constraints are auto-deactivated by UIKit's removeFromSuperview() invariant — clean, but addSubview(dormantLabel) at CBSV:820 is silently load-bearing (removing it would crash init)            
  - Time-zero subscriber state works only because progress defaults to 0; latent risk if initial-p ever changes                                                                                                      
  - scaler bottom-anchored + fixed-height = intentional overflow above panel.top during contraction; contained by panel.clipsToBounds=true (undocumented load-bearing invariant)                                     
  - dormantBlur full-bounds = wasted blur compute mid-transition (alpha→0 by p=1 mitigates)                                                                                                                          
                                                                                                                                                                                                                     
  Three undocumented load-bearing invariants surfaced:                                                                                                                                                               
  1. panel.clipsToBounds=true crops the intentional content overflow                                                                                                                                                 
  2. UIKit's auto-constraint-deactivation makes D1 reparenting safe                                                                                                                                                  
  3. Entire mask-and-mask-position geometry is hardcoded iPhone-16-portrait and won't survive rotation, multitasking, or device change                                                                               
                                                                                                                                                                                                                     
  Frame-update responsibility ledger (cleanly partitioned per agent's analysis): no double-writers, no missed surfaces.                                                                                              
                                                                                                                                                                                                                     
✻ Baked for 14m 21s · 10 local agents still running

⏺ Agent "Trace: hold beat + dissolve floor" completed

⏺ Wave 2 agent #3 (hold beat + dissolve floor) returned. Adds to the synthesis pool:

  Critical findings unique to this branch:
  - C-1 (hottest): hold has TWO definitions that diverge under perturbation — TIMING ARTIFACT (curves don't move) vs STRUCTURAL INVARIANT (bit-identical state). Early-return guards if p <= panelContractionOnsetP {
   return 0 } are silently load-bearing for the structural invariant; refactoring to "the curve approaches zero anyway" would silently downgrade
  - C-3 (principle-j violation): The hold's 0.05p width was never tested at alternatives — emerged as structural residue of scaleFullP=0.45 and panelContractionOnsetP=0.50, not as measured optimum. Per-step
  Δmean=+0.007 confirms the chosen window is still, but does NOT validate the width
  - C-4: The hold beat was never reference-compared (only held-faint was, in D1'). Unknown whether reference has a deliberate hold at all
  - C-5: dissolveFloor + blurMaxFraction is a 1D iso-mean curve, not a point. The codebase documents the mean target (225) but not the texture target ("soft defocus retaining block structure" is prose, not
  metric). Adjacent points on the iso-mean curve preserve mean but shift texture toward frosted-slab failure mode
  - C-6: Matched-shoulder principle correctly asymmetric after p=0.55 — mid-gesture seams require matching (pink end-shoulder at 0.65); end-of-gesture clamps don't (panel arrival at p=1.0). The asymmetry is
  principled but undocumented; could trigger "consistency" refactors

  Cycles: hold-perceptibility ↔ dissolve-slope (coupled oscillator); dissolveFloor ↔ blurMaxFraction (iso-mean); hold-width ↔ shoulder-width

  Frontiers banked: gesture-velocity-dependent hold scaling; reverse-pinch hold semantics; empty-card-stagger as second quiet phase when generation lands

  Doc-seam surfaced: in-source block at line 175 says hold is [0.44, 0.50]; my orchestrator prompt anchored [0.46, 0.50]. 0.44 = blurFullP, 0.46 = dissolveFullP — depending on which channel indexes the hold's left
   edge

  10 more Wave 2 agents in flight.

✻ Churned for 34s · 9 local agents still running

⏺ Agent "Trace: Track B contraction + kink closures" completed

⏺ Wave 2 agent #4 (Track B contraction + kink closures) returned. Dense content. Highest-leverage findings for synthesis:
                                          
  Bedrock added: matched-span discipline is the binding constraint on shoulderSpan=0.05 — it's not a free parameter, fixed by the requirement that pinkMaskAlpha and panelHeightCurve share velocity profile at the
  p=0.50 co-onset.                                                                                                                                                                                                   
  
  New critical findings:                                                                                                                                                                                             
  - Kink ledger is documentation-stale: greyMaskAlpha onset at p=0.75 is referenced at ChatBubbleStackView.swift:594 but the actual onset moved to 0.54 in E3. The ENGINEERING (eased shoulder) is in place at the
  new location; only the ledger text is stale. Doc-drift, no functional impact.                                                                                                                                      
  - shoulderSpan=0.05 encoded as FOUR independent constants (panelContractionOnsetP/EaseEndP, panelWidthOnsetP/EaseEndP). Editing one silently breaks matched-span. Structural risk. Refactor opportunity: single    
  static let shoulderSpan = 0.05 would encode the discipline.                                                                                                                                                        
  - yAtEaseEnd asymmetry (0.10 vs 0.1316) is a derived consequence, not a design choice. Width-shoulder covers 5.66pt vs height-shoulder's 62.6pt of visible motion — width may read as "instant" while height reads 
  as perceptible curve. Unverified perceptually.                                                                                                                                                                     
  - "BENIGN" classification on topFade @ 0.50 is conditional on (a) clamped output AND (b) derivative-insensitive consumer. Neither condition is a compile-time invariant — only comments.                           
                                                                                                                                                                                                                     
  Cycle CY-4 (this branch): the slot-position encoding triangle — cellBottomLift=195 ↔ gradient stops (0.85 pink-light @ 85%) ↔ pinkMask/greyMask geometry (75-100% / 0-20% of viewport). All three implicitly assume
   the others' values. No SSoT.                                                                                                                                                                                      
                                                                                                                                                                                                                     
  Cycle CY-5: the p=0.50 constraint network is densely coupled — panelContractionOnsetP, panelContractionEaseEndP (via shoulderSpan), pinkMaskRecedeOnsetP, pinkMaskOnsetEaseEndP, topFadeFullAtP all meet at or     
  terminate at 0.50. Moving any one without the others breaks at least one of: matched-span discipline, hold-beat bracketing, mask-completion-coincident-with-contraction-start.                                     
                                                                                                                                                                                                                     
  Phantoms (structural-not-code-dead): shoulderSpan-as-four-constants = "phantom of absent encapsulation"; BENIGN classification = "phantom of a test."                                                              
                                                                                                                                                                                                                     
  9 more Wave 2 agents in flight.                                                                                                                                                                                    
                                                                                                                                                                                                                     
✻ Sautéed for 37s · 8 local agents still running                                                                                                                                                                     
                                                                                                                                                                                                                     
⏺ Agent "Trace: F1 shadow + F2 texture closures" completed                                                                                                                                                           
                                                                                                                                                                                                                     
⏺ Wave 2 agent #7 (F1 + F2 + E2 reclassification) returned. Substantial latent-risk surface area. Key findings for synthesis:                                                                                        
                                                                                                                                                                                                                     
  Six new latent-risk CLASSES surfaced (generalizable, not branch-specific):                                                                                                                                         
  1. Taste-as-closure-gate (F1, prospective F1.5) — unfalsifiable, per-reviewer-variable. The F1 dial pattern 0.12 → 0.08 → 0.06 → 0.04 → 0.06 looks like binary-search convergence but is also exactly what         
  taste-noise looks like (bracket-and-overshoot). The "compression confounds measurement" claim was itself never measured — measurement might be viable.                                                             
  2. Undocumented-contract dependency (F1 shadowPath bypass of masksToBounds) — depends on emergent CoreAnimation rendering order, not documented public-API contract. iOS version regression = 100% shadow          
  disappearance, no trip-wire.                                                                                                                                                                                       
  3. Default-as-load-bearing (F2 metadataHidden: Bool = false) — the reversibility property silently depends on the default value. Default-flip would activate spacing-grouping in the WITH-metadata path (never     
  tested). Mitigation: rename to typed enum.                                                                                                                                                                         
  4. Primitive that misleads its integration (F2 metadata-strip) — the primitive's APPROACH is wrong; the integration SPEC is right. F2 code in the codebase = wrong-as-shipped + right-as-learning, easy to misread 
  as recommended approach.                                                                                                                                                                                           
  5. Reclassification reasoning conflation (E2) — mixes "technical infeasibility" with "policy of refusal." E2 is technically buildable in sandbox (sibling CAGradientLayer outside dissolve-floor), just not        
  valuable enough. Honest framing matters for future reclassifications.                                                                                                                                              
  6. Round-level absence: no failure-mode catalog — each round retros "what we learned" but never "here's what broken looks like." Across all rounds.                                                                
                                                                                                                                                                                                                     
  Critical class identification: F2's "right answer is the spec for integration" generalizes to F1.5 and possibly E2 — "primitive proves a coupling exists; the spec for resolving the coupling is integration-tier."
                                                                                                                                                                                                                     
  10 specific action items surfaced (A1-A10) — including pixel-sampling reference shadow noise floor, validating shadowOnsetP=0.85 against reference frames, parameterizing cellBottomLift for slot-position testing,
   sampling reference shadow hue, reverse-pinch verification, gesture-interruption-during-shadow-onset behavior, proto-spec for "paragraph-style flow," pinning canonical reference frame set, adopting failure-mode 
  catalogs.                                                                                                                                                                                                          
                                                                                                                                                                                                                     
  Meta-finding: this trace itself has the F1 problem at meta-level (subjective synthesis). Agent flagged its own subjective conclusions as conjectures.                                                              
                                                                                                                                                                                                                     
  8 more Wave 2 agents in flight.                                                                                                                                                                                    
                                                                                                                                                                                                                     
✻ Cogitated for 29s · 8 local agents still running                                                                                                                                                                   
                                                                                                                                                                                                                     
⏺ Agent "Trace: p-driver SSoT + subscriber seam" completed                                                                                                                                                           
                                                                                                                                                                                                                     
⏺ Wave 2 agent #1 (KEYSTONE: p-driver SSoT + subscriber seam) returned. Most consequential branch — dense findings:                                                                                                  
                                                                                                                                                                                                                     
  Seven Critical Findings (CF#1-CF#7):                                                                                                                                                                               
                                                                                                                                                                                                                     
  CF#1 — Publisher/target fusion: ScalingSurface IS-A UIView AND IS-A publisher; subscriber #1 writes self.scalingSurface.layer.transform. Class doc says "surface itself does NOT compute or apply scale" — yet it  
  IS the transform target. Structural fusion complicating CellView integration: does the cell's content layer BECOME the ScalingSurface, or does a separate ScalingSurface live INSIDE the cell's content layer?     
                                                                                                                                                                                                                     
  CF#2 — Subscriber-ordering implicit-not-guaranteed: Currently safe because no subscriber reads another's downstream effect. Future subscriber reading scaler.bounds mid-fan-out (which Track B subscriber mutates  

  CF#3 — INTEGRATION RISK: no unsubscribe API + cell pool semantics: Cell pool recycles with identity binding (CLAUDE.md Part 2.3). ScalingSurface has NO unsubscribe — append-only for life. If lifted into CellView
   as-is, every activation accumulates subscribers across pool round-trips. Atlas #2 MUST address. Two clean fixes: (a) CSV lifetime == cell lifetime (wire once at pool init), (b) subscribe(_) -> SubscriberToken
  API.

  CF#4 — Immediate-fire is redundant correctness, invisible: Removing handler(progress) from subscribe produces no visible effect at chat-rest because every channel's view state is pre-bootstrapped to p=0 via
  explicit init values. Two independent paths converge on same rest state. A future refactor "simplifying" away the immediate fire would look correct in testing and silently break new channels added later that
  don't pre-bootstrap.

  CF#5 — Seam absorbed D1 refactor without touching SSoT: D1 reparented dormantLabel + split dissolve target — required modifying ONE existing subscriber + ADDING one external subscriber. SSoT class itself did NOT
   change. The seam is not only an extension point for new channels but also a refactoring affordance. Strongest empirical argument for the architecture.

  CF#6 — Pure-function-of-p invariant is by-construction, not by-check: No automated test sweeps p forward + backward asserting identical view-state snapshots. A single state-bearing subscriber added at
  integration would silently break reversibility (= phenomenological violation).

  CF#7 — No commit logic in primitive (.ended/.cancelled unhandled): Pinch handler only handles .began and .changed. p stays at whatever value when gesture ends. Integration MUST add commit logic at canvas level
  per CLAUDE.md Part 2.4.

  9 Bedrock nodes identified including: @MainActor, progress = p write-before-fanout ordering, immediate-fire on subscribe, CATransaction.withSuppressedActions universal, all curves as static func,
  pausesOnCompletion=true on blurAnimator.

  Heat Map (top 3): (1) ScalingSurface itself (publisher), (2) subscribers array + subscribe(_:) method (the seam), (3) pure-function-of-p invariant.

  Phantom hunt: ZERO true phantoms in this branch. D1 refactor is byte-clean. One latent-risk: original CBSV-side dormantLabel constraints rely on UIKit's auto-removal on removeFromSuperview() (corroborates Branch
   8's finding).

  Frontier: cell-pool integration ergonomics + commit/settle behavior post-.ended — both explicitly Atlas #2 territory.

  7 more Wave 2 agents in flight.

✻ Churned for 42s · 4 local agents still running

⏺ Agent "Trace: body→label cross-fade" completed

⏺ Agent "Trace: gradient field + pink/grey masks" completed
                                          
⏺ Agent "Trace warm branches" completed
                                                                                                                                                                                                                     
⏺ Three more Wave 2 agents returned simultaneously. Synthesis pool now contains 8 of 12 branch traces.
                                                                                                                                                                                                                     
  From Agent #6 (body→label cross-fade):                
  - Critical: dissolve subscriber at lines 889-897 does NOT use CATransaction.withSuppressedActions — deviates from CLAUDE.md §2.1 universal discipline (benign for view.alpha typically, but flagged for
  consistency)                                                                                                                                                                                                       
  - dissolveFloor=0.40 is silently triply-load-bearing: held-faint composite + body-out seam + blur-out seam. Warrants explicit keystone status per CLAUDE.md Part 4                                                 
  - Scaler-overflow architectural necessity confirmed: scaler does NOT shrink with panel (only panel shrinks); scaler bottom-anchored with fixed height = content overflows panel.top during contraction. The        
  dormantLabel reparenting was STRUCTURALLY NECESSARY (a CSV-centered label would stay at mid-screen, not cell-center). The reparenting is required, not optional.                                                   
  - bodyContent+dormantBlur joint-fade is INFERRED faithful from joint-signature data (necessary but not sufficient). Channel-level verification not done. Splitting is infrastructurally cheap.                     
  - D1 reparenting reaches past CSV's encapsulation — scaler.dormantLabel.removeFromSuperview() violates CSV's view-tree invariant. Sandbox-acceptable; integration needs explicit CSV API like setDormantLabelHost(_
   host: UIView) or move logic into CSV.                                                                                                                                                                             
  - Font-shift integration risk: at integration, serif Theme.Typography.destinationDate shifts labelInOnsetP's PERCEPTUAL onset ~0.02-0.04 of progress later (serif's thin strokes at α=0.3 are sub-pixel-rendering  
  invisible vs sans). Banked perceptual values may need re-bank at integration.                                                                                                                                      
                                                                                                                                                                                                                     
  From Agent #5 (gradient field):                                                                                                                                                                                    
  - Asymmetric pink vs grey channel treatment surfaced as a finding: pink received E3' transitionWidth=0.10 (sharpened leading edge → 22.5% extent matches ref 22.6%); grey did NOT — uses pre-E3' construction [0,  
  topBoundary]. Grey at p=1.0 is veiled the way pink WAS pre-E3'. Methodology asymmetrically applied. Either grey doesn't matter visually (no reference measurement constrains it) or it's an unaddressed visual     
  debt.                                                                                                                                                                                                              
  - Covert coupling surfaced: gradient stop literal 0.50 is silently equal to (viewportH−cellBottomLift−cellHeight)/viewportH ≈ 0.506 = cell.top fraction. Reader sees 0.50 and may interpret as "half of viewport." 
  Should be derived constant cellTopFraction, not literal.                                                                                                                                                           
  - Self-protective mask-occlusion finding: pinkMask top edge (75% viewport) is 2.1pp ABOVE cell.bot (77.1%) — meaning pinkMask top is occluded by panel at p=1.0. If C4 ever moves such that cell.bot <             
  pinkMask.top, a visible mask edge would appear in the strip between cell.bot and pinkMask.top.                                                                                                                     
  - 5-stop gradient is piecewise-linear sRGB approximation of 4-point HSV climb: CAGradientLayer interpolates linearly in sRGB; the S 11→16→24→29 climb is a curve in HSV space; the 5-stop construction approximates
   HSV via piecewise sRGB segments. Invisible in code (RGB tuples) but architecturally load-bearing.                                                                                                                 
  - E5 contrast delta: build at +18.57 vs reference ≈21 — within tolerance per F1's PRE/POST byte-identical check, but the agent flags the build is INCOMPLETE for E5 strict match.                                  
                                                                                                                                                                                                                     
  From WARM agent (kink ledger + master spec):                                                                                                                                                                       
  - The agent partially mis-contextualized (conflated my sandbox-primitive trace scope with the broader navigation-substrate work from project memory — referenced HANDOFF/K9-K14/G-ARCH-1). But the core principles 
  still surface:                                                                                                                                                                                                     
  - Kink ledger is institutional memory, not executable knowledge — closure verdicts are not enforced anywhere in the codebase                                                                                       
  - The scaleCurve @ 0.12 and 0.45 NOT closed entries remain unresolved (linear curve with velocity kinks at both boundaries — principle (b) partial violation)                                                      
  - The S=71→S=29 correction reveals a fragility class: spec values can be silently wrong; only manual re-analysis caught this one. No automated test asserts AlphaCurve constants produce correct progress-to-alpha 
  shape against reference frames                                                                                                                                                                                     
                                                                                                                                                                                                                     
  Progress: 8 of 12 Wave 2 agents complete. Remaining: Track A channels, Verification methodology, Standing principles, Deferred-integration list.                                                                   
                                                                                                                                                                                                                     
✻ Cooked for 1m 1s · 4 local agents still running                                                                                                                                                                    
                                                                                                                                                                                                                     
⏺ Agent "Trace: Track A channels + crossing points" completed                                                                                                                                                        
                                                                                                                                                                                                                     
⏺ Wave 2 agent #2 (Track A channels + crossing points) returned. Most-detailed trace so far. Eight new critical findings:                                                                                            
                                                                                                                                                                                                                     
  CF-1 — Joint blurMaxFraction × dissolveFloor calibration: pair co-tuned for composite mean ≈ 225, but no code-level link. Modifiable independently. Mitigation: tuning struct + test against reference.            
                                                                                                                                                                                                                     
  CF-1a — Implicit FOUR-channel coupling (not just two): blur × dissolve × top-fade × scale all participate in mean=225, but documentation names only two. scaleAtCellRest is silently part of the calibration locus.
                                                                                                                                                                                                                     
  CF-2 — scaleCurve C¹-violation refined: under the "BENIGN principle," the p=0.45 kink IS benign (y=scaleAtCellRest both sides — saturated), but the p=0.12 kink is NOT (y moves on one side, constant on the       
  other). No code-level justification for why linear was chosen. Risk: principle-literal reviewer would "fix" the curve, drifting the visible scale-onset breakpoint.                                                
                                                                                                                                                                                                                     
  CF-3 — topFadeBoundary tangent precomputation fragility: tangents hardcoded [0.394, 0.734, 1.710, 1.270, 1.670] (line 760). If any knot moves, tangents become stale silently (curve still continuous but no longer
   Fritsch-Carlson monotone — overshoot possible). Inconsistency: blurCurve recomputes tangents at runtime; topFadeBoundary does not. Mitigation path: lift blurCurve's pattern.                                     
                                                                                                                                                                                                                     
  CF-4 — FIVE PHANTOM CONSTANTS: topFadeBoundaryAtRest=0.10, topFadeBoundaryAtFull=1.0, topFadeFullAtP=0.50 declared but never referenced (CF-4 trio). Plus blurOnsetP=0.40 and blurFullP=0.44 are declared but used 
  only in comments — the curves use literal values from blurKnotsP/Y arrays. Failure mode: a tuner edits topFadeFullAtP=0.55 expecting curve to update; nothing changes because the literal 0.50 is inside the array.
                                                                                                                                                                                                                     
  CF-5 — "BENIGN kink" principle stated 3 ways: lines 599-601, lines 322-327, and implicit in scaleCurve's linear choice. Not consolidated. Strict-form reader "fixes" intentional kinks; relaxed-form reader        
  introduces snaps that ARE perceptible.                                                                                                                                                                             
                                                                                                                                                                                                                     
  CF-6 — topFadeKnotsY are CSV-fraction y-values calibrated to specific bubble layout in DummyConversation. Knots K1/K2/K3 are tied to B2/B5/B6 specific message positions. Lifting requires de-anchoring from bubble
   identity.                                                                                                                                                                                                         
                                                                                                                                                                                                                     
  CF-7 — topFadeKnotsP[4]=0.50 is not linked to panelContractionOnsetP=0.50 — coincidence-or-design pair, two channels' hand-off at the same p, but no code expresses the link.                                      
                                                                                                                                                                                                                     
  CF-8 — Subscriber-fan-out order-insensitive TODAY but unguarded: 8 total subscribers (4 internal + 4 external) write to non-overlapping properties. Future subscriber writing bodyContent.alpha would collide with 
  dissolve.                                                                                                                                                                                                          
                                                                                                                                                                                                                     
  Phantom hunt: 5 phantom constants + dormantLabel constraints in CSV init (lines 833-836) DEAD after SandboxViewController reparent — corroborates and refines Agent #1 and Agent #8 findings (third independent    
  surfacing of the same finding from different angles).                                                                                                                                                              
                                                                                                                                                                                                                     
  Heat Map (top 3):                                                                                                                                                                                                  
  1. Composite end-state at p=0.46 (joint calibration locus — CF-1+CF-1a converge)                                                                                                                                   
  2. topFadeBoundary (largest mechanism, CF-3+CF-4+CF-6+CF-7 all live here)                                                                                                                                          
  3. scaleCurve (principle-violation locus, CF-2)                                                                                                                                                                    
                                                                                                                                                                                                                     
  Cycles:                                                                                                                                                                                                            
  - C1: scaleAtCellRest ↔ top-fade bubble-rise correspondence (if scale changes, the rate of bubble-rise into the masked region shifts, but topFade cluster timing stays — misalignment)                             
  - C2: dissolve onset 0.42 ↔ top-fade B6-parking 0.40 (chosen for handoff with 0.02 gap of overlap)                                                                                                                 
                                                                                                                                                                                                                     
  Lens A summary: Track A's mechanism (channels of p, Hermite/smoothstep math, mask, subscriber fan-out) is largely PORTABLE. The calibration values (knot y-positions, breakpoint p-values, scale/blur intensities, 
  dissolve floor) are ENVIRONMENT-COUPLED. The anchor point is REPLACED.                                                                                                                                             
                                                                                                                                                                                                                     
  Progress: 9 of 12 Wave 2 agents complete. Three remaining: verification methodology, standing principles, deferred-integration list.                                                                               
                                                                                                                                                                                                                     
✻ Sautéed for 50s · 3 local agents still running                                                                                                                                                                     
                                                                                                                                                                                                                     
⏺ Agent "Trace: standing principles + epistemology" completed                                                                                                                                                        
                                                                                                                                                                                                                     
⏺ Wave 2 agent #10 (Standing principles a-o) returned. Most thorough Lens F analysis yet. Key findings:                                                                                                              
                                                                                                                                                                                                                     
  Five Phantom Principles (act-like-principles, not formally banked):                                                                                                                                                
  1. Reversibility (curves are reverse-safe by construction via pure-monotone-of-p; not stated as own principle — operationally enforced, verbally absent)                                                           
  2. SSOT for cell geometry (SceneDelegate:181-185 explicitly invokes this for D1; not in (a)-(o) bank)                                                                                                              
  3. Composite-end-state co-tuning (channels co-tuned to composite, not independently; comments at lines 233-238 + 317-319 state this for blur×dissolve but not as named principle)                                  
  4. Hold beat as structural feature (treated as first-class at lines 175-189; not banked)                                                                                                                           
  5. Frame-for-frame match (early principle, dropped — now match compositions, not frames)                                                                                                                           
                                                                                                                                                                                                                     
  Five Cross-Principle Tensions surfaced:                                                                                                                                                                            
  - (c) vs (m) on panelHeightCurve end-kink: (m) says finish both kinks; (c) says benign kinks don't need fixing. (c) wins at panel-height's clamp at p=1.0, but override is implicit. Should be banked: "(m) UNLESS 
  (c) explicitly exempts."                                                                                                                                                                                           
  - (b) vs (c) on scaleCurve: scaleCurve is C⁰ at both breakpoints. (b) demands C¹. (c) excuses BENIGN kinks. The scaleCurve@0.45 benignness rests on COMPOSITE saturation (dissolve+blur masking), not channel      
  - (j) vs (i) on E2: E2 was deferred-to-architecture under (j) attribution; resolved via re-classification under (i). Same item, different principles operating at different times. Need an "evaluation order"
  principle: try (j) AND (i) before architectural commitment.
  - (f) vs reference-validity: (f) trusts reference unconditionally; doesn't equip us to detect when reference is wrong (debug state, compression artifact, intermediate state)
  - (d) vs avoidance: matched-span chosen because reference HAS co-onsets and avoidance would destroy joint-event aesthetic — but (d) doesn't formally state this counterfactual

  15 ABSENT PRINCIPLES identified (the most thorough Lens F):
  1. REVERSIBILITY as named invariant
  2. SSOT for geometry/state
  3. COMPOSITE-END-STATE TUNING DISCIPLINE
  4. SAMPLING DENSITY PROTOCOL for verification ((l) demands sweep but doesn't specify density)
  5. VERIFICATION-CONTEXT SCHEMA ((n) requires context but doesn't enumerate fields)
  6. BENIGN-KINK CONTEXT-PORTABILITY ((c) protects CURRENT clamp location; doesn't say "must bank clamp/saturation dependency")
  7. HOLD-BEAT AS STRUCTURE
  8. REMEDIATION OF MIS-TAGGED ITEMS ((i) classifies; no migration protocol)
  9. FRONTIER LIST REVISIT CADENCE ((j) declines premature deferral; doesn't schedule re-examination)
  10. REFERENCE-VALIDITY GATING ((f) prerequisite not banked)
  11. PRIMITIVE-INTEGRATION INVERSE CONSTRAINT ((o) constrains primitive; symmetric not banked)
  12. METRIC CONSTRUCTION DISCIPLINE
  13. SECOND-DERIVATIVE / C² CONSIDERATION
  14. BREAKPOINT-TUNABLE BANK FORMAT (what depends on topFadeFullAtP=0.50 etc.)
  15. PRIMITIVE PORTABILITY TEST (sandbox is only integration tested; portability is asserted not verified)

  Specific findings on individual principles:
  - (b) interactive curves C¹: scaleCurve's p=0.12 kink is genuine velocity-onset (NOT BENIGN); only its p=0.45 kink is benign by composite-saturation extension
  - (e) Fritsch-Carlson: chosen but rationale not banked (vs Akima or other monotone constructions)
  - (f): unconditional on reference validity
  - (g) metric bundles: no spec of WHICH metrics
  - (h) bg-normalized: no spec of normalization FORM (subtract? divide? perceptual?)
  - (i): operational at Theme.Page.bottom token and cellBottomLift=195 hardcoding — both might be mis-tagged with strict (i)
  - (l) programmatic sweep: NOT universally applied (shadow boundary at 0.85, bodyOut at 0.61, labelIn at 0.71 may be hand-verified only)
  - (m): violated at panelHeightCurve/panelWidthCurve end-kinks, protected by (c) override
  - (n): scaleCurve@0.45 benignness claim lacks dissolve-timing context banking (concrete (n)-failure)

  Progress: 10 of 12 Wave 2 agents complete. Final two in flight: verification methodology, deferred-integration list.

✻ Baked for 55s

⏺ Agent "Trace: verification methodology + banked values" completed

⏺ Agent "Trace: deferred-to-integration list" completed

⏺ All 12 Wave 2 agents complete. Final two add crucial findings:

  Agent #9 (Verification methodology) — most important finding: THE 101-STEP HARNESS IS A PHANTOM. The 101-state schedule producer code, the capture wrapper, and the metric analyzer all live OUTSIDE the tree. The
  sweep_* directories are evidence of past runs; the producers are NOT recoverable from the current commit. The PROVISIONAL register exists ONLY in conversation history. No un-PROVISIONALIZE protocol exists in
  tree. Plus: frame-naming offset confirmed (frame p085.png shows actual p≈0.83); debugReadout label-text changes contaminating "hold dead-still" metric is plausible-but-undiagnosed; recede-σ 0.301→0.399 change
  recorded as bookkeeping not interpreted.

  Agent #11 (Deferred-integration) — surfaces the most important coupling finding from MorphTokens.swift:17: chatRestMarginFactor = 1.10 × naturalCellHeight = 200 = ~938pt at chat-rest, which is TALLER THAN
  VIEWPORT by ~10%. The real chat surface IS effectively full-screen at chat-rest. This confirms E2 reclassification definitively — the gradient is NOT visible during text phase in the real app, gradient only
  emerges as the cell contracts past chat-rest. Also: F2 paragraph-style density doubles dark-pixel mass vs metadata-strip → dissolveFloor=0.40 + blurMaxFraction=0.45 must re-tune (likely floor drops to ~0.30 OR
  blur rises to ~0.55) at integration. Surfaces 9 ABSENCES from the deferred list: cancel-before-threshold, reverse-pinch verification, commitment thresholds, active-cell binding lifecycle, Reduce-Motion,
  tap-to-chat coexistence, pool eviction, sibling cell behavior (followActive), chat content scroll position handoff. Confirms boundary lives at exactly 4 files (SceneDelegate, ChatBubbleStackView:160-935,
  CellView:344-431, Tuning).

  Dispatching Wave 3 synthesis with consolidated input from all 12 branches.

⏺ Agent(Wave 3: Cross-branch synthesis) Opus 4.7
  ⎿  Backgrounded agent (↓ to manage · ctrl+o to expand)

⏺ Hook checks reviewed: Wave 3 prompt contains complete consolidated findings from all 12 Wave 2 branches (read-only operation, no file conflicts, sequential dependency on Wave 4 satisfied by background
  notification mechanism). Updating task tracking.

⏺ Wave 3 synthesis agent dispatched in background. All 12 Wave 2 branch traces consolidated into the synthesis prompt with specific cross-branch hypotheses for the agent to test (shoulderSpan 0.05 hold/Track-B
  linkage; harness-phantom vs F1-reproducibility; dissolveFloor triply-vs-quadruply load-bearing; phantom-classification unification; "right answer is the spec" generalization; chatRestMarginFactor finding's
  silence in other branches; integration-completeness gap from 9 absences).

  Awaiting Wave 3 completion notification. After Wave 3 returns, will dispatch Wave 4 metacognitive adversarial audit with the full trace (Wave 2 + Wave 3 outputs) as input, then assemble the three final artifacts
   (Structured Map + Consequence Narrative + Heat Map Summary).

✻ Cogitated for 3m 55s · 1 local agent still running

⏺ Agent "Wave 3: Cross-branch synthesis" completed

⏺ Wave 3 synthesis complete with 10 cross-cutting conclusions. Most consequential discoveries:
  - D-4 chain: B-6 CATransaction violation → B-1 pure-function-of-p invariant → reversibility → no automated test → silent failure. Four branches each see one link; no branch sees the chain.
  - O-2 ripple: HARNESS IS PHANTOM retrospectively reduces every closure verdict from "closed" to "previously-believed-closed."                                                               
  - The 0.05 quantum: three numerically-identical-but-algebraically-unlinked spans in code (hold-beat width, contraction shoulder, width shoulder). Phantom of absent encapsulation.
  - Phantom taxonomy unification: 5 distinct failure modes all called "phantom" (dead-symbol, absent-encapsulation, absent-artifact, implicit-contract, conversation-only).         
  - Branch 1 missed its own bedrock: named CATransaction.withSuppressedActions as universal discipline but didn't audit call sites — Branch 6 found the violation.                                                   
  - Integration boundary under-traced ~9×: only Branch 11 looked outward.                                                                                         
                                                                                                                                                                                                                     
  Dispatching Wave 4 metacognitive adversarial audit.                                                                                                                                                                
                                                                                                                                                                                                                     
⏺ Agent(Wave 4: Metacognitive adversarial audit) Opus 4.7                                                                                                                                                            
  ⎿  Backgrounded agent (↓ to manage · ctrl+o to expand)                                                                                                                                                             
                                                                                                                                                                                                                     
⏺ Hook checks confirm: Wave 4 prompt is self-contained (all Wave 2 + Wave 3 consolidated findings + all 9 attack vectors + 4 additional holes), read-only verification only, sequential dependency on final assembly 
  satisfied by background notification mechanism.           
                                                                                                                                                                                                                     
⏺ Task tracking unavailable. Wave 4 adversarial agent dispatched in background. Awaiting completion notification before assembling the three final artifacts (Structured Map + Consequence Narrative + Heat Map
  Summary).                                                                                                                                                                                                          
                                                                                                                                                                                                                     
  The Wave 4 agent receives:                                                                                                                                                                                         
  - Consolidated findings from all 12 Wave 2 branches                                                                                                                                                                
  - Wave 3 synthesis with 10 cross-cutting conclusions                                                                                                                                                               
  - All 9 attack vectors from the user's Step 5 prompt (channel-by-channel framework / reference-as-ground-truth / measure-not-guess-applied-to-itself / integration-vs-primitive tags / holistic-pass GO blind spots
   / each ✅ closure-against-gate / you-now-vs-you-in-five-years / designer-vs-engineer / user-vs-builder)                                                                                                           
  - 4 additional holes I identified for explicit attack (trace's authority structure / scope boundary inconsistency / adversarial-vector blind spots in user's own prompt / institutional shape of trace knowledge)  
                                                                                                                                                                                                                   
  When Wave 4 returns, the final assembly produces the three artifacts per Step 6 of the user's prompt — Structured Map (indented tree with per-node                                                                 
  heat/load/integration/rests-on/supports/assumes/verification-context/if-removed/if-changed/phantom-check/terminal), Consequence Narrative (prose through hottest branches), Heat Map Summary (3-5 keystones with   
  cascade justification + critical findings + blind spots + frontiers + recommended actions).
                                                                                                                                                                                                                     
✻ Cogitated for 2m 58s · 1 local agent still running                                                                                                                                                                 
                                                                                                                                                                                                                     
※ recap: Atlas #1 — recursive implication trace of the sandbox pinch primitive — is mid-flight. Wave 3 synthesis returned; Wave 4 adversarial audit is running in background. Next: assemble the three final         
  artifacts (Structured Map, Consequence Narrative, Heat Map Summary) once Wave 4 returns.                                                                                                                           
                                                                                                                                                                                                                     
⏺ Agent "Wave 4: Metacognitive adversarial audit" completed                                                                                                                                                          
                                                                                                                                                                                                                     
⏺ All four waves complete. Wave 4 surfaced devastating findings: Branch 11's chatRestMarginFactor arithmetic is wrong (right answer for wrong reason); Track B contraction mechanism is K11-incompatible with the    
  navigation substrate keystone; CATransaction violation at the dissolve subscriber is a Part 4 KEYSTONE violation, not a stylistic finding; reverse-direction was deferred to integration but K13 makes it          
  primitive; pink/grey gradient channel may be sandbox-only artifact.
                                                                                                                                                                                                                     
  Assembling the three final artifacts now.                                                                                                                                                                          
                                                                                                                                                                                                                     
  ---                                                                                                                                                                                                                
  ATLAS #1 — THE SANDBOX PINCH PRIMITIVE                                                                                                                                                                             
                                                                                                                                                                                                                     
  Complete Implication-Trace Output                                                                                                                                                                                  
                                                                                                                                                                                                                     
  Posture                                                                                                                                                                                                            

  The primitive is closed at the sandbox level and partially mis-closed at the architectural level. The adversarial audit confirms: every closure verdict was made against a verification harness that is no longer  
  in the tree; one closure (Track B contraction mechanism) is architecturally rejected by the navigation-substrate keystone K11 that has been added since the closure was made; one closure (Reverse-direction) is
  tag-misassigned as integration when K13 makes it primitive; one closure (dissolve subscriber lines 889-897) is a Part-4-keystone-discipline violation that the architecture's most authoritative branch missed. The
   atlas reports closure and contradicts closure simultaneously, by design. Trust the contradiction.                                                                                                                 
   
  ---                                                                                                                                                                                                                
  I. THE STRUCTURED MAP                                     
                                              
  The recursive tree. Each entry carries [HEAT] · LOAD · INTEGRATION · TERMINAL. Multi-line entries name rests-on / supports / assumes / verification-context / if-removed / if-changed / phantom-check. Format is
  indented; subtrees descend.                 
                                                                                                                                                                                                                     
  ROOT: The sandbox pinch primitive
  │   Heat: HOT · Load: KEYSTONE · Integration: PARTIALLY PORTABLE / PARTIALLY REPLACED                                                                                                                              
  │   Rests on: ScalingSurface SSoT; reference video; iOS 18 / iPhone 16 sim; UIKit
  │              framework conventions; CLAUDE.md phenomenological commitment                                                                                                                                        
  │   Supports: integration of choreography into real app's CellView/ChatContentContainer
  │   Assumes: pure-function-of-p invariant (BY CONSTRUCTION, NOT BY CHECK — CF#6)                                                                                                                                   
  │            sandbox primitive must never become source of truth (principle o)                                                                                                                                     
  │            HARNESS-WAS-MEASURED-AND-DISCARDED (now PHANTOM)                                                                                                                                                      
  │   Verification context: 101-step sweep iOS 18 iPhone 16 UDID C149C833-...                                                                                                                                        
  │                          BUT: harness producer not in tree (Branch 9)                                                                                                                                            
  │   If removed: V2RootViewController still works; choreography knowledge banked                                                                                                                                    
  │                in conversation history + this atlas remains                                                                                                                                                      
  │   If changed: structurally would need to remain a single-scalar-driven pure-function                                                                                                                             
  │                pattern OR every subscriber path collapses                                                                                                                                                        
  │   Phantom check: ENTIRE ATLAS may be operating on conversation-only knowledge                                                                                                                                    
  │                   per Wave 4 Hole H-4                                                                                                                                                                            
  │   Terminal: CRITICAL FINDING (this is Atlas #1; Atlas #2 traces the integration target)                                                                                                                          
  │                                                                                                                                                                                                                  
  ├── 1. p-DRIVER SSoT + subscriber seam                                                                                                                                                                             
  │   │   Heat: HOT · Load: KEYSTONE · Integration: PORTABLE (with caveats)                                                                                                                                          
  │   │   Rests on: UIView inheritance (incidental); @MainActor 9S contract;                                                                                                                                         
  │   │              `progress: CGFloat = 0` initial value; sync `for handler` loop
  │   │   Supports: every channel; the D1 refactor; the F1 + F2 retrofits                                                                                                                                            
  │   │   Assumes: subscribers are pure functions of p (NO STATE-BEARING SUBSCRIBER);                                                                                                                                
  │   │            no recursion mid-fan-out; cell-pool lifetime = subscriber lifetime                                                                                                                                
  │   │            (FALSE for cell pool — CF#3)                                                                                                                                                                      
  │   │   Verification context: Code inspection + grep for `progress` writes; NO                                                                                                                                     
  │   │                          automated forward+backward sweep test exists (CF#6)                                                                                                                                 
  │   │   If removed: every visible property collapses to inert defaults                                                                                                                                             
  │   │   If changed: making async produces 4-channel race; introducing state breaks                                                                                                                                 
  │   │                reversibility                                                                                                                                                                                 
  │   │   Phantom check: NO unsubscribe API exists; subscribers append-only for life;                                                                                                                                
  │   │                   integration-into-cell-pool will accumulate subscribers                                                                                                                                     
  │   │   Terminal: BEDROCK at @MainActor; CRITICAL FINDING at CF#1-CF#7                                                                                                                                             
  │   │                                                                                                                                                                                                              
  │   ├── 1.1 ScalingSurface (publisher) IS-A UIView AND IS-A transform target                                                                                                                                       
  │   │   Heat: HOT · Load: KEYSTONE · Integration: PORTABLE-as-publisher,                                                                                                                                           
  │   │                                              ENVIRONMENT-COUPLED-as-target                                                                                                                                   
  │   │   Class doc says "does NOT compute or apply scale" — yet IS the transform target                                                                                                                             
  │   │   (Subscriber #1 writes self.scalingSurface.layer.transform). Structural fusion.                                                                                                                             
  │   │   If changed: separating publisher from target requires either repointing                                                                                                                                    
  │   │                subscriber #1 OR adding a parallel surface                                                                                                                                                    
  │   │   Terminal: CRITICAL FINDING (CF#1)                                                                                                                                                                          
  │   │                                                                                                                                                                                                              
  │   ├── 1.2 Subscribers array + subscribe()/setProgress()                                                                                                                                                          
  │   │   Heat: HOT · Load: KEYSTONE · Integration: PORTABLE                                                                                                                                                         
  │   │   8 active subscribers (4 internal in CSV init; 4 external in SVC viewDidLoad)                                                                                                                               
  │   │   Order-insensitive TODAY (no property collision); UNGUARDED against                                                                                                                                         
  │   │   future ordering-dependent additions (CF#2 + CF-8 across branches)                                                                                                                                          
  │   │   No unsubscribe; no SubscriberToken; cell-pool lifetime risk (CF#3)
  │   │   immediate-fire on subscribe is redundant-but-load-bearing correctness (CF#4)                                                                                                                               
  │   │   Phantom check: behaviorally clean; latent integration risk                                                                                                                                                 
  │   │   Terminal: BEDROCK                                                                                                                                                                                          
  │   │                                                                                                                                                                                                              
  │   ├── 1.3 Pure-function-of-p invariant                                                                                                                                                                           
  │   │   Heat: HOT · Load: KEYSTONE · Integration: PORTABLE                                                                                                                                                         
  │   │   Rests on: every curve as `static func`; no state-bearing subscriber                                                                                                                                        
  │   │   Verification context: BY CONSTRUCTION, NOT BY CHECK
  │   │   **WAVE 4 ATTACK D-4 CHAIN**: B-6 CATransaction violation at lines 889-897                                                                                                                                  
  │   │   threatens this invariant. Setting UIView.alpha implicitly cascades to                                                                                                                                      
  │   │   layer.opacity which IS implicitly animated. The pure-function claim
  │   │   becomes time-dependent silently.                                                                                                                                                                           
  │   │   Terminal: CRITICAL FINDING (B-1 bedrock + B-6 audit miss)                                                                                                                                                  
  │   │                                                                                                                                                                                                              
  │   └── 1.4 Pinch handler / state schedule entry points                                                                                                                                                            
  │       Heat: HOT-handler / COOL-schedule · Load: LOAD-BEARING / DECORATIVE                                                                                                                                        
  │       Integration: PORTABLE-mapping / REPLACED-attachment                                                                                                                                                        
  │       log-pinch-to-p mapping (`-log(pinchScale) / logScaleSpan`) portable
  │       Recognizer attachment site sandbox-specific; TimelineCanvas owns at integration                                                                                                                            
  │       CF#7: NO .ended/.cancelled handling; commit logic deferred (but K13 says PRIMITIVE)                                                                                                                        
  │       Terminal: CRITICAL FINDING (CF#7 tag-misassignment)                                                                                                                                                        
  │                                                                                                                                                                                                                  
  ├── 2. TRACK A — Content recede (composite end-state mean ≈ 225)                                                                                                                                                   
  │   │   Heat: HOT · Load: KEYSTONE · Integration: ENVIRONMENT-COUPLED                                                                                                                                              
  │   │   Rests on: scaleCurve, blurCurve, topFadeBoundary, contentDissolveAlpha                                                                                                                                     
  │   │              composing visually in the GPU compositor                                                                                                                                                        
  │   │   Supports: the breath beat; B6 anchor; the visible "reference signature"                                                                                                                                    
  │   │   Assumes: blurMaxFraction × dissolveFloor JOINT calibration (CF-1)                                                                                                                                          
  │   │            FOUR-channel coupling silent (CF-1a): blur × dissolve × top-fade × scale                                                                                                                          
  │   │            sRGB-linear interpolation produces perceptually correct climb                                                                                                                                     
  │   │            (Branch 5: 5-stop is approximation of HSV in sRGB — invisible)                                                                                                                                    
  │   │   Verification context: 101-step sweep, captured pre/post F1 and F2;                                                                                                                                         
  │   │                          HARNESS PRODUCER NOT IN TREE (Branch 9)                                                                                                                                             
  │   │   If removed: entire morph becomes scale + nothing — visually inert                                                                                                                                          
  │   │   If changed: any single channel adjustment requires re-verification against                                                                                                                                 
  │   │                composite mean ≈ 225 (Branch 3: 1D iso-mean curve)                                                                                                                                            
  │   │   Phantom check: FIVE PHANTOM CONSTANTS in topFade (Branch 2 CF-4):                                                                                                                                          
  │   │                   topFadeBoundaryAtRest, topFadeBoundaryAtFull, topFadeFullAtP,                                                                                                                              
  │   │                   blurOnsetP, blurFullP — declared, never referenced                                                                                                                                         
  │   │   Terminal: CRITICAL FINDING (multi-channel joint-calibration locus)                                                                                                                                         
  │   │                                                                                                                                                                                                              
  │   ├── 2.1 scaleCurve (linear, p=0.12→0.45, scale=1.0→0.40)                                                                                                                                                       
  │   │   Heat: HOT · Load: LOAD-BEARING · Integration: PORTABLE-math /                                                                                                                                              
  │   │                                                   ENVIRONMENT-COUPLED-value                                                                                                                                  
  │   │   The ONLY non-C¹ active curve. Principle (b) partially violated.
  │   │   p=0.12 kink: NOT BENIGN (y moves on one side) — true principle violation                                                                                                                                   
  │   │   p=0.45 kink: BENIGN by composite-saturation extension (stretch of principle c)                                                                                                                             
  │   │   No code justification for "why linear" anywhere (CF-2)                                                                                                                                                     
  │   │   Phantom check: bookkeeped as closed; kink-ledger says "scaleCurve NOT closed"                                                                                                                              
  │   │   Terminal: CRITICAL FINDING (CF-2; principle b/c tension)                                                                                                                                                   
  │   │                                                                                                                                                                                                              
  │   ├── 2.2 blurCurve (5-knot Fritsch-Carlson; UIViewPropertyAnimator scrubbing)                                                                                                                                   
  │   │   Heat: HOT · Load: LOAD-BEARING · Integration: PORTABLE                                                                                                                                                     
  │   │   Runtime tangent recomputation (correctly robust to blurMaxFraction tuning)                                                                                                                                 
  │   │   pausesOnCompletion=true is BEDROCK for the scrubbing trick                                                                                                                                                 
  │   │   blurMaxFraction × dissolveFloor JOINT calibration (CF-1)                                                                                                                                                   
  │   │   Terminal: PORTABLE                                
  │   │                                                                                                                                                                                                              
  │   ├── 2.3 topFadeBoundary (5-knot Hermite, Fritsch-Carlson tangents PRECOMPUTED)                                                                                                                                 
  │   │   Heat: HOT · Load: LOAD-BEARING · Integration: ENVIRONMENT-COUPLED                                                                                                                                          
  │   │   Knot p-values [0.0, 0.17, 0.27, 0.40, 0.50] hardcoded as LITERAL ARRAY                                                                                                                                     
  │   │   topFadeKnotsP[4] = 0.50 = panelContractionOnsetP — coincidence-or-design,                                                                                                                                  
  │   │   NO CODE-LEVEL LINK (Branch 2 CF-7; Wave 3 D-1 0.50 attractor)                                                                                                                                              
  │   │   Tangents [0.394, 0.734, 1.710, 1.270, 1.670] HARDCODED — if knot moves,                                                                                                                                    
  │   │   tangents become stale (CF-3 vs blurCurve's runtime recomputation INCONSISTENCY)                                                                                                                            
  │   │   y-values are CSV-FRACTION coordinates calibrated to specific bubble layout                                                                                                                                 
  │   │   (CF-6 — methodology-punch-listed)                                                                                                                                                                          
  │   │   BENIGN math-kink at p=0.50: protected ONLY by clamp at line 768                                                                                                                                            
  │   │   (Branch 4: "phantom of a test"); fragile under topFadeFullAtP move                                                                                                                                         
  │   │   Terminal: CRITICAL FINDING (CF-3, CF-4, CF-6, CF-7 all live here)                                                                                                                                          
  │   │                                                                                                                                                                                                              
  │   ├── 2.4 contentDissolveAlpha + body-out + label-in extensions                                                                                                                                                  
  │   │   Heat: HOT · Load: KEYSTONE · Integration: PORTABLE-mechanism /                                                                                                                                             
  │   │                                              ENVIRONMENT-COUPLED-floor                                                                                                                                       
  │   │   dissolveFloor=0.40 is SILENTLY POLYPHONICALLY load-bearing (Wave 3 D-3):                                                                                                                                   
  │   │     (1) held-faint composite mean                                                                                                                                                                            
  │   │     (2) body-out seam start value (must equal floor for C0-continuity)                                                                                                                                       
  │   │     (3) blur-out seam start value                                                                                                                                                                            
  │   │     (4) topFade composite floor contribution                                                                                                                                                                 
  │   │     (5) scaleAtCellRest perceptual interaction                                                                                                                                                               
  │   │   **WAVE 4 KEYSTONE VIOLATION** at lines 889-897:                                                                                                                                                            
  │   │   Dissolve subscriber writes bodyContent.alpha + dormantBlur.alpha                                                                                                                                           
  │   │   WITHOUT `CATransaction.withSuppressedActions`. CLAUDE.md Part 4 universal                                                                                                                                  
  │   │   discipline violation. UIView.alpha cascades to layer.opacity which IS                                                                                                                                      
  │   │   implicitly animated. Branch 1 named this discipline as BEDROCK but did                                                                                                                                     
  │   │   not audit; Branch 6 caught it; Wave 4 weighted it as KEYSTONE-level.                                                                                                                                       
  │   │   Terminal: CRITICAL FINDING (D-4 cross-branch dependency chain)                                                                                                                                             
  │   │                                                                                                                                                                                                              
  │   └── 2.5 The 0.05 quantum + 0.50 attractor (cross-branch finding)                                                                                                                                               
  │       Heat: HOT · Load: KEYSTONE · Integration: ENVIRONMENT-COUPLED                                                                                                                                              
  │       The value 0.05 appears at THREE numerically-identical-but-algebraically-                                                                                                                                   
  │       unlinked spans: hold-beat width (scaleFullP→panelContractionOnsetP),
  │       contraction shoulder (panelContractionOnsetP→panelContractionEaseEndP),                                                                                                                                    
  │       width shoulder (panelWidthOnsetP→panelWidthEaseEndP).                                                                                                                                                      
  │       The value 0.50 appears at panelContractionOnsetP, pinkMaskRecedeOnsetP,                                                                                                                                    
  │       topFadeKnotsP[4], gradient stop literal (≈0.506 cell.top fraction).                                                                                                                                        
  │       NO SSoT; future tuner breaks silently.                                                                                                                                                                     
  │       Terminal: CRITICAL FINDING (Wave 3 B-6 newly-synthesized bedrock)                                                                                                                                          
  │                                                                                                                                                                                                                  
  ├── 3. HOLD BEAT (p ∈ [0.46, 0.50])                                                                                                                                                                                
  │   │   Heat: HOT · Load: KEYSTONE · Integration: PORTABLE-as-structure                                                                                                                                            
  │   │   The phenomenological pivot: the breath between Track A and Track B.                                                                                                                                        
  │   │   Branch 3 C-1: TIMING ARTIFACT (curves don't move) vs STRUCTURAL INVARIANT                                                                                                                                  
  │   │   (bit-identical state) — two interpretations diverge under perturbation.                                                                                                                                    
  │   │   Enforced via early-return guards `if p <= panelContractionOnsetP { return 0 }`                                                                                                                             
  │   │   which are SILENTLY LOAD-BEARING for the structural invariant.                                                                                                                                              
  │   │   C-3: 0.05p width NEVER tested at alternatives (principle j violation).                                                                                                                                     
  │   │   C-4: never reference-compared (only held-faint was, in D1').                                                                                                                                               
  │   │   Terminal: CRITICAL FINDING                                                                                                                                                                                 
  │   │                                                                                                                                                                                                              
  ├── 4. TRACK B — Panel contraction (panelHeightCurve + panelWidthCurve)                                                                                                                                            
  │   │   Heat: HOT · Load: LOAD-BEARING-IN-SANDBOX / **K11-INCOMPATIBLE-AT-INTEGRATION**                                                                                                                            
  │   │   Integration: REPLACED (mechanism, not value)                                                                                                                                                               
  │   │   **WAVE 4 ATTACK 2 #1**: Mechanism is REJECTED by navigation substrate K11.                                                                                                                                 
  │   │   K11: "cell does not move; camera does" + cell height is CONSTANT during gesture.                                                                                                                           
  │   │   Sandbox panel CONTRACTS height via heightConstraint.constant mutation.                                                                                                                                     
  │   │   The entire Track B work is closure-against-sandbox, NOT closure-against-architecture.                                                                                                                      
  │   │   Re-engineer as camera.scale per K10/K13/K14 at integration.                                                                                                                                                
  │   │   Matched-shoulder discipline (Branch 4) survives mechanism change; values transfer.                                                                                                                         
  │   │   shoulderSpan=0.05 encoded as FOUR independent constants — phantom of absent encapsulation                                                                                                                  
  │   │   Kink ledger is documentation-STALE: greyMaskAlpha onset @ 0.75 referenced;                                                                                                                                 
  │   │   actual moved to 0.54 in E3 (no doc update)                                                                                                                                                                 
  │   │   yAtEaseEnd asymmetry (0.10 vs 0.1316) = derived consequence, unverified perceptually                                                                                                                       
  │   │   Slot-position TRIANGLE: cellBottomLift ↔ gradient stops ↔ mask geometry; no SSoT                                                                                                                           
  │   │   Terminal: CRITICAL FINDING (architecture rejection)                                                                                                                                                        
  │                                                                                                                                                                                                                  
  ├── 5. GRADIENT FIELD + masks (pinkMask + greyMask + reveal)                                                                                                                                                       
  │   │   Heat: HOT · Load: LOAD-BEARING-IN-SANDBOX / **MAY BE SANDBOX-ONLY**                                                                                                                                        
  │   │   Integration: REPLACED (substrate-level)                                                                                                                                                                    
  │   │   **WAVE 4 ATTACK 2 #4**: Real-app cell exceeds viewport at chat-rest                                                                                                                                        
  │   │   (chatRestMarginFactor=1.10 × viewport, NOT × naturalCellHeight — Branch 11                                                                                                                                 
  │   │   arithmetic was wrong but conclusion right). NO "below-cell area" to reveal.                                                                                                                                
  │   │   The whole pink/grey mask channel may be a sandbox-only artifact.                                                                                                                                           
  │   │   E2 reclassification confirmed but on GEOMETRIC grounds, not policy grounds.                                                                                                                                
  │   │   Asymmetric pink vs grey treatment: pink got E3' transitionWidth=0.10                                                                                                                                       
  │   │   sharpening; grey did NOT (uses pre-E3' construction). Methodology asymmetry.                                                                                                                               
  │   │   Covert coupling: gradient stop literal 0.50 ≈ cell.top fraction 0.506                                                                                                                                      
  │   │   Self-protective: pinkMask top (75%) is occluded by panel; if cell.bot < 75%,                                                                                                                               
  │   │   visible mask edge appears (C4 triangle hazard).                                                                                                                                                            
  │   │   Terminal: CRITICAL FINDING (sandbox-only artifact possibility)                                                                                                                                             
  │                                                                                                                                                                                                                  
  ├── 6. BODY→LABEL CROSS-FADE (D1+D1'+D2-mech+D3)                                                                                                                                                                   
  │   │   Heat: HOT · Load: LOAD-BEARING · Integration: PORTABLE-mech / REPLACED-content                                                                                                                             
  │   │   contentDissolveAlpha extended with body-out segment [0.61, 0.66] → 0                                                                                                                                       
  │   │   labelInAlpha [0.71, 0.78] (de-gated; integration extends to 0.86 with sparkle)                                                                                                                             
  │   │   0.05 empty-card beat — at fast gestures may compress below perceptibility                                                                                                                                  
  │   │   dormantLabel REPARENTING (D1): structurally NECESSARY (not optional) because                                                                                                                               
  │   │   scaler does NOT shrink with panel — only panel shrinks; a CSV-centered label                                                                                                                               
  │   │   would stay at mid-screen, not cell-center.                                                                                                                                                                 
  │   │   Reparenting reaches PAST CSV's encapsulation (sandbox-acceptable; integration                                                                                                                              
  │   │   needs CSV API like `setDormantLabelHost(_ host: UIView)`)                                                                                                                                                  
  │   │   **Dissolve subscriber CATransaction violation** lives here (see 2.4 entry).                                                                                                                                
  │   │   bodyContent + dormantBlur joint-fade is INFERRED faithful, NOT channel-verified.                                                                                                                           
  │   │   Splitting infrastructurally cheap (writes already independent).                                                                                                                                            
  │   │   Font-shift integration risk: serif at integration shifts perceptual onset                                                                                                                                  
  │   │   ~0.02-0.04 of progress later.                                                                                                                                                                              
  │   │   Terminal: CRITICAL FINDING (D-4 chain; D-3 polyphonic floor)                                                                                                                                               
  │                                                                                                                                                                                                                  
  ├── 7. F1 SHADOW + F2 TEXTURE + E2 RECLASSIFICATION (final round)                                                                                                                                                  
  │   │   Heat: HOT · Load: LOAD-BEARING · Integration: REPLACED at multiple boundaries                                                                                                                              
  │   │   F1: shadowPath bypass of masksToBounds — UNDOCUMENTED-CONTRACT PHANTOM                                                                                                                                     
  │   │   (depends on emergent CoreAnimation rendering order, not public API contract)                                                                                                                               
  │   │   F1 closure via "4-iteration dial-back" 0.12→0.08→0.06→0.04→0.06 = TASTE-AS-                                                                                                                                
  │   │   CLOSURE-GATE (unfalsifiable per-reviewer-variable)                                                                                                                                                         
  │   │   F2 metadataHidden default=false is DEFAULT-AS-LOAD-BEARING phantom                                                                                                                                         
  │   │   F2 finding "right answer is the spec, not the implementation" generalizes                                                                                                                                  
  │   │   (Wave 3 R-1)                                                                                                                                                                                               
  │   │   E2 reclassified PRIMITIVE→INTEGRATION; **WAVE 4** confirms correct verdict                                                                                                                                 
  │   │   for new reason: integration cell exceeds viewport so gradient never visible                                                                                                                                
  │   │   during text phase regardless of mechanism                                                                                                                                                                  
  │   │   F1.5 (panel-edge softening) banked as proto-spec; not built; mechanism                                                                                                                                     
  │   │   candidates: UIVisualEffectView sibling / CAFilter / CASoftEdgeLayer-style mask                                                                                                                             
  │   │   **WAVE 4 H-3**: F1's shadowPath + panel.clipsToBounds is on collision course                                                                                                                               
  │   │   that no branch surfaced.                                                                                                                                                                                   
  │   │   Terminal: CRITICAL FINDING                                                                                                                                                                                 
  │                                                                                                                                                                                                                  
  ├── 8. VIEW HIERARCHY + COMPOSITION                                                                                                                                                                                
  │   │   Heat: HOT · Load: LOAD-BEARING · Integration: REPLACED (sandbox is whole-VC)                                                                                                                               
  │   │   THREE UNDOCUMENTED LOAD-BEARING INVARIANTS:                                                                                                                                                                
  │   │   (i) panel.clipsToBounds=true contains scaler-overflow above panel.top                                                                                                                                      
  │   │       — scaler height is FIXED at safeAreaH=759; panel contracts; overflow                                                                                                                                   
  │   │       is intentional and silently clipped
  │   │   (ii) UIKit auto-deactivation on removeFromSuperview() makes D1 reparenting                                                                                                                                 
  │   │        clean — original CBSV-side constraints (CBSV:820, 833-836) become                                                                                                                                     
  │   │        zombies handled by framework; CBSV:820 silently load-bearing                                                                                                                                          
  │   │   (iii) iPhone-16-portrait geometry LOCKED — viewportW=393, viewportH=852,                                                                                                                                   
  │   │         safe areas, mask heights, cellBottomLift all hardcoded; will not                                                                                                                                     
  │   │         survive rotation, multitasking, device family change                                                                                                                                                 
  │   │   Time-zero state works ONLY because progress defaults to 0 (initial values                                                                                                                                  
  │   │   pre-bootstrap to p=0 state independently)                                                                                                                                                                  
  │   │   Frame-update responsibility ledger cleanly partitioned (no double-writers,                                                                                                                                 
  │   │   no missed surfaces) — confirmed by Branch 8 audit                                                                                                                                                          
  │   │   Terminal: CRITICAL FINDING (3 undocumented invariants)                                                                                                                                                     
  │                                                                                                                                                                                                                  
  ├── 9. VERIFICATION METHODOLOGY                                                                                                                                                                                    
  │   │   Heat: HOT · Load: WAS-KEYSTONE-NOW-PHANTOM · Integration: PORTABLE-as-pattern                                                                                                                              
  │   │   **HARNESS IS PHANTOM** (Branch 9 + Wave 3 O-2):                                                                                                                                                            
  │   │   101-state schedule producer not in tree           
  │   │   Capture wrapper not in tree                                                                                                                                                                                
  │   │   Metric analyzer not in tree                                                                                                                                                                                
  │   │   ONLY ARTIFACTS PRESENT: sweep_output/, sweep_f1/, sweep_f1_final/, sweep_f2/                                                                                                                               
  │   │   directories (~200MB total) and _video_audit/ (22MB reference frames)                                                                                                                                       
  │   │   PROVISIONAL register exists ONLY in conversation history                                                                                                                                                   
  │   │   No un-PROVISIONALIZE protocol in tree             
  │   │   Δmean blindness: lateral motion, color hue rotations preserving luminance,                                                                                                                                 
  │   │   sub-quantization events, motion blur, joint-perception artifacts across                                                                                                                                    
  │   │   multiplied channels                                                                                                                                                                                        
  │   │   Spec-error pattern from S=71→S=29 reveals fragility class: "Blur sharpness                                                                                                                                 
  │   │   220→8" likely declared not measured; shadow color "black" unmeasured;                                                                                                                                      
  │   │   cell aspect 1.55-1.60 single-frame                                                                                                                                                                         
  │   │   Reference video pipeline UNSPECIFIED: 788x1662 (@2x) vs build 1179x2556                                                                                                                                    
  │   │   (@3x); 21pt height difference + bezel + keyboard + extra cards                                                                                                                                             
  │   │   Calibration mapping f40↔p=0.66 is EYEBALL-DERIVED — all downstream metrics                                                                                                                                 
  │   │   inherit uncertainty                                                                                                                                                                                        
  │   │   Frame-naming offset: `p085.png` shows actual p≈0.83                                                                                                                                                        
  │   │   debugReadout label-text changes may contaminate "hold dead-still" metric                                                                                                                                   
  │   │   σ 0.301→0.399 across F2 recorded as BOOKKEEPING, never interpreted                                                                                                                                         
  │   │   Terminal: CRITICAL FINDING (most consequential meta-finding of entire trace)                                                                                                                               
  │                                                                                                                                                                                                                  
  ├── 10. STANDING PRINCIPLES a-o                                                                                                                                                                                    
  │   │   Heat: HOT · Load: KEYSTONE-FRAMEWORK · Integration: PORTABLE-AS-DOCTRINE                                                                                                                                   
  │   │   Five PHANTOM PRINCIPLES (operationally enforced, not formally banked):                                                                                                                                     
  │   │     1. Reversibility (curves reverse-safe by construction; not named)                                                                                                                                        
  │   │     2. SSOT for cell geometry (panel.bounds-driven; explicit in code but not bank)                                                                                                                           
  │   │     3. Composite-end-state co-tuning (joint blur×dissolve; named in comments only)                                                                                                                           
  │   │     4. Hold-beat as structural feature (treated first-class; not banked)                                                                                                                                     
  │   │     5. Frame-for-frame match (early principle, dropped quietly)                                                                                                                                              
  │   │   Five cross-principle TENSIONS:                                                                                                                                                                             
  │   │     (c) vs (m) on panelHeightCurve end-kink                                                                                                                                                                  
  │   │     (b) vs (c) on scaleCurve (p=0.12 kink NOT BENIGN by literal c)                                                                                                                                           
  │   │     (j) vs (i) on E2                                                                                                                                                                                         
  │   │     (f) vs reference-validity                                                                                                                                                                                
  │   │     (d) vs avoidance for co-onsets                  
  │   │   FIFTEEN ABSENT PRINCIPLES enumerated (see Heat Map Summary)                                                                                                                                                
  │   │   Terminal: CRITICAL FINDING (principle bank is incomplete + uncodified)                                                                                                                                     
  │                                                                                                                                                                                                                  
  ├── 11. DEFERRED-TO-INTEGRATION LIST (boundary mapping)                                                                                                                                                            
  │   │   Heat: HOT · Load: BOUNDARY · Integration: REPLACED (10 items, all confirmed)                                                                                                                               
  │   │   10 items confirmed REPLACED at integration:                                                                                                                                                                
  │   │     D2-content / D4 sparkle / C4 real slot / F3 typography / B2 keyboard                                                                                                                                     
  │   │     E2 gradient (RECLASSIFIED via WAVE 4 — geometric grounds)                                                                                                                                                
  │   │     F2-content (paragraph-style spec — dissolveFloor/blurMaxFraction must re-tune)                                                                                                                           
  │   │     Role-signaling (real renderer design decision)                                                                                                                                                           
  │   │     F1.5 panel-edge softening (mechanism candidates surveyed)                                                                                                                                                
  │   │     Methodology re-sampling                                                                                                                                                                                  
  │   │   **NINE ABSENCES FROM DEFERRED LIST** (Branch 11):                                                                                                                                                          
  │   │     1. Cancel-before-threshold (gesture commit logic)                                                                                                                                                        
  │   │     2. Reverse-pinch verification (**K13 SAYS PRIMITIVE — TAG MISASSIGNMENT**)                                                                                                                               
  │   │     3. Commitment thresholds (velocity-aware)                                                                                                                                                                
  │   │     4. Active-cell binding lifecycle (setActiveCellIndex)
  │   │     5. Reduce-Motion (Wave 4: not a primitive concern; tag question)                                                                                                                                         
  │   │     6. Tap-to-chat coexistence                                                                                                                                                                               
  │   │     7. Pool eviction / memory pressure                                                                                                                                                                       
  │   │     8. Sibling cell behavior (followActive)                                                                                                                                                                  
  │   │     9. Chat content scroll position handoff                                                                                                                                                                  
  │   │   Boundary at exactly 4 files: SceneDelegate (whole sandbox), CSV at                                                                                                                                         
  │   │   ChatBubbleStackView:160-935, CellView.swift:344-431 (setCamera funnel),
  │   │   Tuning.swift (naturalCellHeight=200 ground truth)                                                                                                                                                          
  │   │   Terminal: CRITICAL FINDING (integration boundary) 
  │                                                                                                                                                                                                                  
  └── 12. KINK LEDGER + MASTER SPEC (WARM consolidated)                                                                                                                                                              
      │   Heat: WARM · Load: INSTITUTIONAL MEMORY · Integration: SUPERSEDED-IN-PLACE                                                                                                                                 
      │   Kink ledger is institutional memory, NOT executable knowledge                                                                                                                                              
      │   scaleCurve @ 0.12 and 0.45 NOT closed — explicit open entries                                                                                                                                              
      │   Master spec was DECLARATIVE-PRECEDES-EMPIRICAL until S=71→S=29 correction                                                                                                                                  
      │   Document drift: ledger references stale onset positions (greyMaskAlpha at                                                                                                                                  
      │   0.75 mentioned at line 594; actual is 0.54)                                                                                                                                                                
      │   Terminal: BEDROCK (institutional memory) + FRONTIER (re-bake against architecture)                                                                                                                         
                                                                                                                                                                                                                     
  ---                                                                                                                                                                                                                
  II. THE CONSEQUENCE NARRATIVE                                                                                                                                                                                      
                                                                                                                                                                                                                     
  This is the story the structured map cannot tell. It walks through the hottest branches and conveys the WEIGHT of the dependencies — what carries what, which keystones the gesture rests on, which assumptions    
  could quietly break at integration.                                                                                                                                                                                
                                                                                                                                                                                                                     
  The thread of greatest consequence          
                                                                                                                                                                                                                     
  Start with the verification methodology. The codebase claims a 101-step holistic sweep produced "no seams" at the documented co-onsets, the hold beat reads dead-still at Δ+0.007, the total dynamic range matches
  the reference within 9%. These are real measurements of real screenshots. They are also calibrated against a measurement apparatus that no longer exists in the tree. Branch 9 surfaced this; the SceneDelegate    
  currently holds a 10-state demo schedule; the 101-state producer was reverted; the metric analyzer was external. The PROVISIONAL register exists in conversation history alone. Every closure verdict in the entire
   atlas — every ✅ status, every "verified," every "byte-identical pre/post" — rests on a harness that has been disassembled. This is not a recoverable state. A new contributor reading the code cannot reproduce a
   single closure.                                          
                                                                                                                                                                                                                     
  This single finding ripples through every branch. F1's "4-iteration dial-back" verified against captured frames? The harness is gone. The v23 end-of-A signature mean=232.1, p5=226, dark-cov=5.8%? Calibrated
  against the harness. The "composite mean ≈ 225 at p=0.46"? Same. The "delta 18.57 vs reference 21 for top-edge contrast"? Same. None are independently verifiable from the current tree.

  The trace had a second moment of architectural reckoning. Branch 11 surfaced chatRestMarginFactor = 1.10 and naturalCellHeight = 200 and produced the conclusion that the real-app cell exceeds the viewport at    
  chat-rest by ~10%. The arithmetic was wrong (1.10 is a multiplier on the ratio viewport.height / naturalHeight, not on naturalCellHeight), but the conclusion was right. The right conclusion via the wrong
  reasoning: an adversarial gift. Because the conclusion is right, the entire E2 reclassification (gradient field visible during text phase as an integration concern, not a primitive concern) is confirmed — but on
   geometric grounds, not on the policy grounds Branch 7 originally articulated. The gradient is not visible during text phase because there is no below-cell area to reveal: the cell IS the viewport.              
   
  This in turn raises the question: if the cell IS the viewport at chat-rest, does the entire pink/grey gradient field machinery have a referent in the real app at all? The sandbox built it as a load-bearing      
  mechanism for the late-phase reveal; if at chat-rest the cell occupies the full viewport (which it does in the real app), the masks have no domain to reveal until the cell contracts past chat-rest. Branch 5
  (gradient field) measured the entire mechanism extensively without ever cross-checking against this geometric fact. The whole gradient channel may be a sandbox-only artifact.
                                                                                                                                                                                                                     
  The K11 incompatibility                     
                                                                                                                                                                                                                     
  Wave 4 found the deepest single contradiction: CLAUDE.md keystone K11 says "cell does not move; camera does — cell height is constant during gesture." The sandbox's Track B mechanism contracts the panel's height
   via panelHeight.constant = viewportH + (cellHeight - viewportH) * tH every frame. The mechanism is architecturally rejected. Track B's closure (panelHeightCurve, panelWidthCurve, matched-shoulder discipline,   
  the entire kink ledger for Track B) is closure-against-sandbox, not closure-against-architecture. At integration, the contraction MUST be re-engineered as camera.scale per K10/K13/K14. The choreography values
  (curves, timing, shoulders) transfer; the mechanism does not. The trace did not flag this; the audit caught it.                                                                                                    
                                                            
  This is not a minor concern. It changes what "closure" means. The 4 weeks of work on Track B's eased shoulders, the matched-span discipline, the kink-ledger closures at panel/pink/grey co-onsets — all of it     
  remains correct as choreography and wrong as mechanism. The 0.50 attractor (Wave 3 B-6) becomes more brittle because three of the four channels meeting at 0.50 (panelHeightCurve, panelWidthCurve, pinkMaskAlpha)
  live on the rejected substrate; only topFadeBoundary survives unchanged.
                                                                                                                                                                                                                     
  The dissolve subscriber that breaks the bedrock
                                                                                                                                                                                                                     
  Branch 6 found that the dissolve subscriber at ChatBubbleStackView.swift:889-897 writes bodyContent.alpha = a and dormantBlur.alpha = a WITHOUT a surrounding CATransaction.withSuppressedActions block. This
  deviates from CLAUDE.md Part 4's "implicit-animation suppression is universal" discipline. Branch 1 (the keystone branch, the architecture's most authoritative) listed CATransaction.withSuppressedActions as
  Bedrock #5. Branch 1 then did not audit its own bedrock claim against the actual call sites. Branch 6 caught it. Wave 4 weighted it: this is a Part 4 KEYSTONE violation, not a stylistic finding.
                                                                                                                                                                                                                     
  The chain (Wave 3 D-4): the dissolve subscriber's missing CATransaction → CoreAnimation's implicit kCAOnOrderIn-style fade fires on UIView.alpha writes (which cascade to layer.opacity) → the layer transition
  takes 0.25s by default → during a 120Hz pinch, each frame's alpha write is interpolating from the previous frame's value → the pure-function-of-p invariant breaks silently because bodyContent.alpha becomes      
  time-dependent → reverse-pinch no longer retraces identical values → the phenomenological commitment "time is unbroken; the gesture is reversible" is structurally violated → no automated test detects this
  (Branch 1 CF#6: pure-function-of-p is by-construction, not by-check). Four branches each see one link; no branch saw the chain.                                                                                    
  
  The secret harmonics                                                                                                                                                                                               
                                                            
  The value 0.05 appears in the code at three numerically-identical-but-algebraically-unlinked spans. The value 0.50 appears at four. Future tuners change one without knowing the others depend. The trace surfaces
  this via Wave 3 synthesis B-6; no single branch saw all instances. There is no static let shoulderSpan: CGFloat = 0.05 constant; there is no static let trackAEndP: CGFloat = 0.50 constant. The discipline that
  makes these values matter (matched-span Hermite shoulders at co-onsets) lives in comments. Five years from now, a maintainer who changes panelContractionOnsetP to 0.48 will not know that topFadeKnotsP[4] is the
  same number for a structural reason — and the comment block four screen-scrolls away will not be found.                                                                                                            
  
  What the design eye does not see                                                                                                                                                                                   
                                                            
  The trace measured luminance, mean, p5, dark-coverage, transition extents, contrast deltas, frame counts. It did not measure color emotion, brand voice, type character, motion rhythm, the difference between a
  resigned dissolve and a surrendering one. F1's shadow dialed via taste-as-closure-gate is the entire trace in microcosm: the engineer dialed a parameter until a luminance delta matched a reference luminance
  delta; whether the shadow feels like this product's shadow is a question the trace cannot phrase. F3 typography is deferred to integration, but a designer would say the typography IS the destination card's soul
  — not a deferral, a primary decision.                                                                                                                                                                              
  
  This is the broadest sandbox-vs-integration tension: the primitive measures what can be measured, and the design questions live in what cannot. The trace's confidence is calibrated against a measurement frame;  
  the integration's success is calibrated against a perceptual frame; the two frames do not align. Branch 7's "primitive that misleads its integration" framing generalizes to a class: any closure that closes 
  against measurement may reopen against perception.
                                                                                                                                                                                                                     
  The trace as the artifact
                                                                                                                                                                                                                     
  The synthesis observed, and the audit confirmed, that this atlas is the densest representation of knowledge about the primitive that exists. The code does not contain the kink ledger's analytic shape; the
  comments do not link 0.50 across channels; the tests do not assert pure-function-of-p reversibility; the verification harness is absent from the tree. The atlas is the system's institutional memory in this
  domain. And the atlas is conversation-bound. Without an export pipeline, ADR protocol, or test-case generator, the atlas decays into the same fragility as the PROVISIONAL bankings: known once, then forgotten.
                                                                                                                                                                                                                     
  ---
  III. THE HEAT MAP SUMMARY                                                                                                                                                                                          
                                                            
  One page. Executive view.               

  The five keystones (removal cascades concretely)                                                                                                                                                                   
                                          
  1. The p-driver SSoT + subscriber seam. Remove it, every channel collapses to inert defaults. The whole primitive depends on the pure-function-of-p invariant routed through a single ScalingSurface publisher with
   4 internal + 4 external subscribers. Threat to keystone: the dissolve subscriber at lines 889-897 violates CATransaction.withSuppressedActions, silently breaking the invariant the keystone is supposed to       
  enforce.
  2. The composite end-state at p=0.46 (mean ≈ 225). Joint calibration locus of blurMaxFraction × dissolveFloor, but actually four channels (blur × dissolve × topFade × scale) all participate in producing the     
  calibrated composite. Any one channel adjustment requires re-verification against the full composite. Threat to keystone: the verification harness that produced "≈225" no longer exists in the tree.
  3. The 0.50 attractor. Four channels independently land at p=0.50: panelContractionOnsetP, pinkMaskRecedeOnsetP, topFadeKnotsP[4], gradient stop literal (≈0.506 = cell.top fraction). No SSoT links them. Removing
   any one breaks the joint hand-off; changing any one silently breaks an unlisted relationship.
  4. panel.clipsToBounds = true. Undocumented load-bearing invariant. Contains the intentional scaler-overflow above panel.top during contraction (scaler is fixed-height at safeAreaH=759; panel contracts to       
  cellHeight=226; difference is silently clipped). Remove the clip, scaler content bleeds above the cell card.
  5. The HARNESS (now phantom). The 101-state schedule producer, the simctl capture wrapper, the metric analyzer. Every closure verdict in the atlas was calibrated against this harness. Its absence retrospectively
   reduces every "✅ closed" status to "previously-believed-closed."
                                                                                                                                                                                                                     
  Critical findings (the discoveries that change understanding)
                                                                                                                                                                                                                     
  - HARNESS IS PHANTOM — reproducibility of every closure compromised
  - Track B mechanism is K11-incompatible — entire contraction work is closure-against-sandbox, not closure-against-architecture                                                                                     
  - Dissolve subscriber CATransaction violation at lines 889-897 — Part 4 keystone violation breaks pure-function-of-p silently
  - Reverse-direction is K13 PRIMITIVE, tag-misassigned as INTEGRATION — primitive deferral with architecture-significant consequence                                                                                
  - chatRestMarginFactor finding: right conclusion via wrong arithmetic — real-app cell exceeds viewport at chat-rest, gradient channel may be sandbox-only
  - Five phantom constants in topFade (topFadeBoundaryAtRest, topFadeBoundaryAtFull, topFadeFullAtP, blurOnsetP, blurFullP) — declared, never referenced                                                             
  - The 0.05 quantum at three unlinked sites + the 0.50 attractor at four — secret harmonics                                                                                                                         
  - Phantom taxonomy is five distinct failure modes all called "phantom" (dead-symbol / absent-encapsulation / absent-artifact / implicit-contract / conversation-only)                                              
  - Branch 1's bedrock list contained an unchecked claim — Branch 6 found the violation; meta-warning on bedrock declarations                                                                                        
  - The trace itself is the densest knowledge representation; it is conversation-bound                                                                                                                               
                                                                                                                                                                                                                     
  Blind spots (the audit found these; the trace did not)                                                                                                                                                             
                                                                                                                                                                                                                     
  - Performance / thermal / energy — zero trace content. UIVisualEffectView is expensive; per-tick gradient stop mutation; shadow rasterization; 120Hz subscriber fan-out. May fail under thermal throttling at      
  30fps.                                                                                                                                                                                                             
  - Accessibility beyond Reduce-Motion — Dynamic Type, VoiceOver, Bold Text, Increase Contrast, Switch Control. None measured.                                                                                       
  - iOS-version variance — pinned to iOS 18 / iPhone 16. CoreAnimation timing primitives change between major OS versions.                                                                                           
  - Dark mode — Theme.Cell.shadowColor = UIColor.black.cgColor invisible against dark background.
  - RTL languages — centerX/centerY semantics unchanged but text alignment may invert.                                                                                                                               
  - Multitasking / split-view — viewport reshape during gesture untested.                                                                                                                                            
  - Designer concerns — color emotion, brand voice, typography character, motion rhythm. The trace measures luminance and bookkeeps parameters; perception lives in unmeasured dimensions.                           
  - User-experience variance — gesture-velocity-dependent hold beat (75ms at 1.5s gesture compresses to <16ms at 0.3s gesture); reverse-pinch perceptual asymmetry; commit-threshold expectation mismatch; haptic    
  absence; multi-pinch reset behavior; pinch outside cell bounds.                                                                                                                                                    
  - Sibling cell behavior during pinch (followActive exists at CellView.swift:500-509; the sandbox has only one panel)                                                                                               
  - Pool eviction / memory pressure (teardownChatContentForMemoryPressure at CellView.swift:485-490)                                                                                                                 
  - Two-cell pinch (start on cell A, finish on cell B) — sandbox has one panel; can't even think this case                                                                                                           
                                                                                                                                                                                                                     
  Frontiers (where external research is needed)                                                                                                                                                                      
                                                                                                                                                                                                                     
  - HARNESS reconstruction — commit the 101-state schedule producer + capture wrapper + metric analyzer back to scripts/ for reproducibility                                                                         
  - K11 reconciliation — Track B's contraction mechanism must be re-engineered against camera.scale (not heightConstraint) before integration                                                                        
  - Integration boundary trace — Atlas #2 to symmetrically trace the existing real-app codebase                                                                                                                      
  - Reverse-direction primitive verification — programmatic reverse-sweep with measured perceptual targets (currently only partial)                                                                                  
  - Designer-eye verification pass — color emotion, type character, motion rhythm against the design intent
  - Performance / thermal baseline — sustained-scrub CPU/GPU/memory profile                                                                                                                                          
  - Reference-validity gating protocol — when is the reference video itself the wrong target?                                                                                                                        
  - C² consideration — current C¹ via Hermite suffices for smooth scrubs; under extreme finger velocity, C² discontinuities (acceleration jumps) may become perceptible                                              
  - Accessibility audit — Reduce-Motion path, Dynamic Type at XXL, VoiceOver announcements, Increase Contrast composite-end-state behavior                                                                           
                                                                                                                                                                                                                     
  Recommended actions for integration                                                                                                                                                                                
                                                                                                                                                                                                                     
  Before any integration work begins:                                                                                                                                                                                
                                                                                                                                                                                                                     
  1. Materialize PROVISIONAL bankings to code. Every PROVISIONAL value (v23 end-of-A, resting CSV-region mean, recede-σ, F1 shadow params) gets a named constant in a BankedCalibration enum with WHY comments. Bank 
  tightens; conversation can rot.                                                                                                                                                                                    
  2. Add InvariantHardeningTests for:
    - panelContractionOnsetP == topFadeKnotsP[4] (the 0.50 attractor)                                                                                                                                                
    - panelContractionEaseEndP - panelContractionOnsetP == panelWidthEaseEndP - panelWidthOnsetP (the 0.05 quantum)
    - scaleFullP < panelContractionOnsetP (declared invariant at line 188)
    - blurFullP < scaleFullP (declared invariant at line 187)
    - Pure-function-of-p reversibility: sweep p forward 0→1 capturing N frames; sweep p reverse 1→0; assert byte-identical at matched p
    - CATransaction.withSuppressedActions wrapping around every layer-property write in the subscriber chain
  3. Fix the dissolve subscriber's CATransaction omission at ChatBubbleStackView.swift:889-897 immediately. This is a load-bearing keystone violation.
  4. Reconcile Track B mechanism with K11. Re-engineer panel contraction as camera.scale (not heightConstraint) per K10/K13/K14. The choreography values transfer; the mechanism changes.
  5. Reclassify Reverse-direction as PRIMITIVE per K13. Bank the reverse-pinch semantics; add programmatic reverse-sweep verification.
  6. Re-check every banking that cites specific arithmetic against code. Branch 11's chatRestMarginFactor arithmetic was wrong; others may be too. Treat the atlas as a hypothesis set, not a fact set, on
  arithmetic.
  7. Convert phantom constants to either deleted-dead-code OR referenced-in-arrays. Edit topFadeFullAtP to be the value the curve actually uses, OR delete it.
  8. Decide the F1 + panel.clipsToBounds collision before F1.5 is built (Wave 4 H-3 finding).
  9. Commission a designer-eye pass before declaring visual closure on any item.
  10. Reconstruct the verification harness to scripts/sweep_harness.swift + scripts/analyze_sweep.py (or equivalent). Without this, the atlas is the only verifiable artifact, and the atlas is conversation-bound.
  11. Bank the integration absences (cancel-before-threshold, commitment thresholds, active-cell binding lifecycle, sibling behavior, scroll handoff, pool eviction, tap-to-chat coexistence) as explicit Atlas #2
  frontiers.
  12. Export this atlas to docs/ as ADR-style artifacts before the conversation ends. The trace is the institutional memory.

  ---
  Acceptance Criteria Audit (per Step 7 of user prompt)

  - ✅ Every tuned constant has PORTABLE/COUPLED/REPLACED classification with environmental dependency named for COUPLED (Lens A applied across branches 1-7 + 9 + verified in 11)
  - ✅ Every INTEGRATION-tagged item has seam map (Lens E in Branch 11)
  - ✅ Every Q6 absence is classified (Lens F in Branches 1-12 + Wave 4 Attack 9)
  - ✅ Phantom hunt reports findings for 10 classes (Branches 1, 2, 4, 5, 7, 8, 9 + Wave 3 synthesis taxonomy)
  - ✅ Every closed item's verification context documented; protocol-aged verifications flagged (Branch 9 Lens D table)
  - ✅ 5 keystones identified and justified with concrete cascade
  - ✅ Adversarial audit produced findings (Wave 4 produced 9 attacks + 4 holes + top adversarial findings + things-trace-got-right + don't-assume warnings)
  - ✅ Synthesis identified shared bedrock + hidden inter-branch dependencies (Wave 3 Sections 1-2)

  Atlas #1 is complete. It claims closure and contradicts closure simultaneously, by design. The contradictions are the most valuable output. The integration trace (Atlas #2) is now structurally positioned to
  start with this atlas as its prior, and explicitly reject the atlas's K11-incompatible mechanism choices, reverse-direction tag misassignment, and the phantom verification harness.

  If Atlas #2 encounters a surprise this atlas should have surfaced, the atlas failed. Reading this atlas, the integration round must NOT assume the primitive's curves transfer unchanged, must NOT assume Track B
  mechanism is portable, must NOT assume panel.clipsToBounds=true carries over, must NOT assume the dissolve subscriber is correct as-is, must NOT assume reference video is reproducible, must NOT assume
  PROVISIONAL bankings survive a new conversation, must NOT assume the secret harmonics are tracked, must NOT assume commit logic is BEDROCK, must NOT assume designer concerns will be addressed at integration,
  must NOT assume performance/accessibility/iOS-variance/dark mode/RTL/dynamic type/thermal have been verified. Zero trace content on any of the last set.

  The bar was complete coverage with full depth. Within the frame the trace traced, this atlas meets it. The frame itself is one of the trace's findings. Trust the contradiction.
ATLAS #1 — ADVERSARIAL PASS 2 — Hostile Re-Audit of Sandbox Primitive      

  Burden inverted. The atlas is presumed incomplete; I will prove where. Wave 4 already surfaced ~12 critical findings; this pass attacks what Wave 4 missed.
                                          
  ---
  PERSONA 1 — The Integration Engineer Doing the Merge                                                                                                                                                               
                                                      
  F1.1 — The "PORTABLE log-pinch-to-p mapping" wasn't traced through origin variance.                                                                                                                                
                                                            
  Branch 1.4 classified the gesture mapping p = -log(recognizer.scale) / logScaleSpan as PORTABLE. SceneDelegate:340 reads recognizer.scale directly — but UIPinchGestureRecognizer.scale is RATIO from gesture-begin
   to current, not absolute. In the sandbox, the gesture begins at the chat-rest visual state where scale starts at 1.0, so p=0 maps to scale=1. In the real app, the gesture begins from CELL-REST, where the panel
  is already contracted. There is no canonical "begin at chat-rest" anchor. The mapping ASSUMES a fixed origin that the integration target does not provide. The atlas waved past this with "log mapping is          
  portable."                                                                                                                                                                                                         
                                                                                                                                                                                                                     
  F1.2 — The "4-file boundary at exactly SceneDelegate + ChatBubbleStackView:160-935 + CellView:344-431 + Tuning" undercounts.                                                                                       
                                                            
  Branch 11 named four files. Missed at minimum:
  - Theme.swift (F1 wired Theme.Cell.shadowOpacityCellRest etc.; F1 finding's parameters cross the boundary into the real CellView's chrome installation site at CellView:191-194)                                   
  - TimelineDataSource.swift — provides per-cell slot geometry that cellBottomLift=195 stands in for; Branch 11 referenced CellLayoutTuning.naturalCellHeight but didn't enumerate TimelineDataSource as a boundary
  file                                                                                                                                                                                                               
  - MorphTokens.swift (chatRestMarginFactor=1.10 lives here; Wave 4 referenced it but never named it as a boundary file)
  - CellView.swift:9-583 (not just :344-431) — installSubviews, installLayout, the 6 appliers, performMorphChromeTransition, applyChatContentScaleFade. The atlas truncated CellView's boundary to the camera funnel 
  and missed where Track A's chrome lands.                  
                                                                                                                                                                                                                     
  Boundary is at least 7 files, not 4.                      
                                                                                                                                                                                                                     
  F1.3 — The "shoulderSpan=0.05 portable, values transfer" claim has no propagation proof.                                                                                                                           
                                                                                                                                                                                                                     
  Branch 4 found shoulderSpan encoded at four sites. The atlas asserts the matched-shoulder math (cubic Hermite + linear tail in panelHeightCurve at lines 485-514) transfers. But panelHeightCurve reads            
  shoulderSpan implicitly through (p - panelContractionOnsetP) / (panelContractionEaseEndP - panelContractionOnsetP). At the integration target, panelContractionOnsetP and EaseEndP may need different values to    
  match the real cell's contraction range (driven by camera.scale per K11, not heightConstraint). The portability claim presumed the divisor stays algebraically equivalent; the math was never re-checked under the
  K10-substituted mechanism.                                                                                                                                                                                         
                                                            
  F1.4 — Fritsch-Carlson tangents are precomputed and unreproducible.                                                                                                                                                
                                                            
  Branch 2 CF-3 surfaced this. But the atlas's "remediation" was "lift blurCurve's runtime pattern." Lifting requires the Fritsch-Carlson formula, which is not in the codebase. The integration engineer needs:
  m_i = ((y_{i+1} - y_i)/(x_{i+1} - x_i) + (y_i - y_{i-1})/(x_i - x_{i-1})) / 2                                                                                                                                      
  adjusted if signs of (y_{i+1}-y_i) and (y_i-y_{i-1}) differ → set to 0       
  adjusted via Fritsch-Carlson monotone-preserving step                                                                                                                                                              
  Without this, the integration engineer treats the literal [0.394, 0.734, 1.710, 1.270, 1.670] as opaque magic numbers. The atlas surfaced fragility but provided no remediation contract.
                                                                                                                                                                                                                     
  F1.5 — The Atlas #1 → Atlas #2 handoff has no export schema.                                                                                                                                                       
                                                                                                                                                                                                                     
  The atlas concludes with "Atlas #2 should not assume X, Y, Z." It never produces an export contract: a structured list of (curve_name, file_line_range, math_form, knot_array, tangent_array,                      
  environmental_assumptions, replacement_status). The integration engineer must re-derive each interface manually. The atlas is doctrine without API.                                                                
                                                                                                                                                                                                                     
  F1.6 — The atlas listed metadataHidden: Bool = false as the reversibility lever, but didn't trace propagation through ChatContentContainer.                                                                        
                                                                                                                                                                                                                     
  ChatBubbleView.swift:9 takes metadataHidden. ChatBubbleStackView's configure has a metadataHidden parameter. But the real-app integration path is ChatContentContainer.configure → bubbleStack.configure(with:)    
  with NO metadataHidden argument. So the real app uses default-false. The atlas's F2 finding ("paragraph-style spec for integration renderer") is a future spec, but the CURRENT integration mechanically defaults  
  to metadata-full. The reversibility flag is non-load-bearing in the real-app path today — there's no production caller setting it true. Either:
  - F2 finding is unactioned (renderer is metadata-full in real app)                                                                                                                                                 
  - F2 finding requires modifying ChatContentContainer.configure to thread the flag
                                                                                                                                                                                                                     
  The atlas surfaced neither.                               
                                                                                                                                                                                                                     
  ---
  PERSONA 2 — The Maintainer Inheriting This in 2028                                                                                                                                                                 
                                                            
  F2.1 — "Reference video" has no provenance.                                                                                                                                                                        
                                                            
  The atlas refers to _video_audit/f001.png-f060.png at 788x1662. Where did the video come from? Designer prototype? Screencap of competitor app? Custom render? The atlas does not say. Calibration of f40 ↔ p=0.66 
  is "eyeball-derived." Without source, the maintainer cannot re-acquire if frames go missing. Wave 4 noted recording-context uncertainty; the deeper miss is naming the SOURCE of the reference.
                                                                                                                                                                                                                     
  F2.2 — F1 closure looks like binary search, was actually taste.                                                                                                                                                    
                                          
  The dial sequence 0.12 → 0.08 → 0.06 → 0.04 → 0.06 is documented in 1.6 (sweep_output → sweep_f1 → sweep_f1_final). To a maintainer, it reads "binary search converging on 0.06 after rejecting 0.04 as too quiet."
   No test asserts shadow opacity = 0.06 produces correct perceptual output. iOS shadow rendering has changed between OS versions (e.g., iOS 17 → 18 changed shadow gamma compensation). A maintainer on iOS 20      
  inherits 0.06 thinking it's measured; it was tasted on iOS 18.
                                                                                                                                                                                                                     
  F2.3 — Principle (o) "primitive must never become source of truth" is violated by F2 finding's elevation.
                                                                                                                                                                                                                     
  The atlas's F2 banked finding ("paragraph-style flow needed for real renderer") IS being treated as a source of truth for the integration's renderer design. The primitive's σ-measurement (0.301 → 0.399) became 
  the renderer spec. Either the principle is wrong, or the finding-banking violates it. The atlas published a principle and a finding that contradicts the principle in the same closure round.                      
   
  F2.4 — D1' rebanking 0.93 → 0.71 for labelInOnsetP is unmotivated.                                                                                                                                                 
                                                            
  The atlas says "0.71 was de-gated, integration extends to 0.86 with sparkle." Why exactly 0.71? Why not 0.70 or 0.72? The maintainer integrating sparkle needs to know the decision basis: is 0.71 minimal (just   
  enough breathing room from body-out at 0.66) or is it perceptually targeted (matching reference at some specific p)? The 0.05 empty-card beat falls out arithmetically, but the choice of 0.71 specifically is     
  conversation-only.
                                                                                                                                                                                                                     
  F2.5 — Gradient color sampling protocol lives in conversation only.
                                                                                                                                                                                                                     
  Theme.swift:30 documents gradientGreyMid = RGB(217,213,218) with comment "Sampled approximately at V=85 between top.V=73 and surface.V=93." Which reference frame? Which y-coordinate? Median across how many 
  frames? Theme.swift:22 documents bottom = RGB(204,145,148) with HSV labels and "sampled from frame_0055..0060." The protocol is partial: frames named, y-coord not, sampling method not. A maintainer who wants to
  re-sample after a reference update has no protocol to follow.
                                                                                                                                                                                                                     
  F2.6 — The σ jump 0.301 → 0.399 was bookkept, never explained.
                                                                                                                                                                                                                     
  Branch 9 noted this. The atlas's hypothesis ("metadata-strip → shorter bubbles → more body content fits viewport → more text to dissolve") was conversation-only. The codebase does not document the mechanism. A
  maintainer who wants to push σ back down doesn't know whether the lever is metadata, density, or both.                                                                                                             
   
  F2.7 — scaleCurve NOT closed is stuck without a closure path.                                                                                                                                                      
                                                            
  The kink ledger explicitly lists scaleCurve @ p=0.12 and p=0.45 as OPEN. The atlas's Wave 4 confirmed p=0.12 kink is genuine (not BENIGN). But the atlas provides no closure proposal: should scaleCurve become    
  Hermite-eased on both shoulders? Should (b) be amended? Should the kink be tolerated permanently? The maintainer inherits a permanently-open kink with no closure roadmap.                                         
  
  ---                                                                                                                                                                                                                
  PERSONA 3 — The Phantom That Wants to Survive (10-class re-hunt)
                                                                                                                                                                                                                     
  Wave 4 found phantoms; I'll find more by hunting actively.
                                              
  F3.1 — Self.sandboxMode = true flag in SceneDelegate is a dead conditional branch.
                                          
  SceneDelegate:6 declares private static let sandboxMode = true. SceneDelegate:18 selects V2RootViewController() unconditionally; the sandbox routing branch at lines 19-21 is commented out. The atlas listed      
  SandboxViewController as the running app but never verified the wiring. The sandbox is gated behind a flag whose conditional has been disabled. Class 9 (dead conditional).                                        
                                                                                                                                                                                                                     
  F3.2 — The 10-state demo schedule (SceneDelegate:317-328) is vestigial.                                                                                                                                            
                                                            
  Listed in 1.6 as "current schedule." But: it's a DispatchQueue.main.asyncAfter chain that drives setProgress(p) at hand-picked p-values [(0.0, "start"), (0.4, ...), ...]. This is demo-theater that runs on top of
   the pinch handler. If both demo AND pinch are wired, they race. If only demo is wired and sandboxMode=true is the gate, then sandboxMode=false (commented branch) → no demo, no pinch. Both paths are broken right
   now: the wired production path is V2RootViewController, where the demo schedule never executes. Class 7 (vestigial state, mid-refactor leftover).
                                                                                                                                                                                                                     
  F3.3 — debugReadout UILabel ships to production behavior. 
                                                                                                                                                                                                                     
  SceneDelegate:48 declares private let debugReadout = UILabel(). SceneDelegate:240-246 fires every frame setting debugReadout.text = .... Is this gated by #if DEBUG? Searching the file shows it's not. If
  sandboxMode is ever flipped true, debugReadout ships to users. Class 1 (dead symbol shipping live).                                                                                                                
  
  F3.4 — Theme.Cell.fill = #f6efef is not unused — it's a divergence.                                                                                                                                                
                                                            
  Atlas 1.2.C explicitly flagged: "Theme.Cell.fill: candidate phantom — unused at primitive layer; panel uses surface." But the real app's CellView.installSubviews uses Theme.Cell.fill (confirmed from CellView's  
  chrome installation reading the Theme.Cell tokens). The primitive's panel fill is Theme.Page.surface = RGB(237,233,238). The real cell's fill is Theme.Cell.fill = #f6efef = RGB(246,239,239). The colors differ by
   ~9 RGB points each channel. The primitive's "E5 panel-as-bright-band" was tuned against Theme.Page.surface; the real cell uses Theme.Cell.fill. The +18.57 vs +21 edge-contrast measurement transfers with a color
   shift. Class 4 (implicit-contract divergence between primitive and integration).                                                                                                                                  
                                                            
  F3.5 — viewDidLayoutSubviews shadowPath update may lag under contraction.                                                                                                                                          
                                                            
  SceneDelegate:90-93 updates shadowPath in viewDidLayoutSubviews. UIKit batches layout calls. During Track B contraction (panel height changing per-frame from p=0.50 to p=1.0), panel.bounds changes per frame,
  which triggers viewDidLayoutSubviews. But UIKit batches these — under load, multiple bounds changes can collapse into a single layoutSubviews call. Then the shadowPath is computed from the final bounds of that  
  batch, but the layer.shadowOpacity is being driven by the continuous subscriber at full 120Hz. Shadow may lag panel by 1 frame at thermal throttling. Class 4 (implicit timing contract).
                                                                                                                                                                                                                     
  F3.6 — Dormant CBSV-side dormantLabel constraints (CBSV:833-836) are zombie code.
                                                                                                                                                                                                                     
  Wave 4 noted these. But what's missed: the original CBSV-side constraints reference dormantLabel.centerXAnchor.constraint(equalTo: scalingSurface.centerXAnchor) etc. If the integration revives a CSV-inside path
  (e.g., a different use of ContentScalerView), these constraints reawaken and conflict with the panel-reparented constraints (SceneDelegate:226-229). The atlas's "auto-deactivation by removeFromSuperview()"      
  handling is only sandbox-runtime safe; not source-safe. Class 7.
                                                                                                                                                                                                                     
  F3.7 — pinkBoundary/greyBoundary subscriber writes during p∈[0, 0.50] are computational waste.
                                                                                                                                                                                                                     
  SceneDelegate:278 writes pinkMask gradient locations = [pinkBoundary, pinkBoundary + 0.10] every frame. For p ≤ pinkMaskRecedeOnsetP = 0.50, pinkMaskAlpha(p) = 1.0 (mask fully opaque). The
  CAGradientLayer.locations write at frame N+1 == frame N. 120 wasted writes per second during Track A. Class 1 (functionally dead computation). Mitigation: gate subscriber writes behind value-change check.       
  
  F3.8 — sweep_* directories on disk are absent artifacts.                                                                                                                                                           
                                                            
  1.6 lists sweep_output/, sweep_f1/, sweep_f1_final/, sweep_f2/ as "build artifacts on disk." Are these checked into git or .gitignored? The atlas does not say. If gitignored, they vanish on next checkout. If    
  committed, the repo bloats with ~200MB of PNG. Either failure mode is a phantom (artifact absent OR repo-polluting). Class 3.                                                                                      
  
  F3.9 — /tmp/* files referenced in F1 dial-back iterations are doubly-volatile.                                                                                                                                     
                                                            
  1.6 lists /tmp/iter1_opacity008.png through /tmp/iter4_op006_r8.png and /tmp/ours_p100_crop.png. These are in /tmp/. On macOS, /tmp/ is auto-cleaned every few days. The F1 dial-back evidence is                  
  already-or-imminently lost. The reasoning that compared iter2 vs iter3 perceptually is unverifiable. Class 3 (more volatile than sweep_*).                                                                         
  
  F3.10 — Reference frames at 788×1662 (@2x) vs build at 1179×2556 (@3x) — resolution mismatch.                                                                                                                      
                                                            
  1.6 documents reference frames at 788×1662 (= 2x of 394×831 logical). Build frames at 1179×2556 (= 3x of 393×852). The logical viewports differ by 21pt vertically (831 vs 852, due to bezel/notch interpretation).
   All banked y-positions are in build's coordinate system, but the reference's coordinate system is 21pt shorter. Bench-marking band edges, top-fade y-positions, cellBottomLift fraction-of-viewport — all         
  calibrated under coordinate-system-translation that the atlas did not capture as a verification context field. Class 5.
                                                                                                                                                                                                                     
  F3.11 — Tests/V2/* directory was treated as silent corroboration.
                                                                                                                                                                                                                     
  The atlas's 1.1 enumeration notes "Tests files exist but were not touched in primitive rounds." But Wave 4's recommendations (action 2: "add InvariantHardeningTests") presume the test suite is alive. Are the 
  tests actually run in CI? Are they passing today? The atlas references InvariantHardeningTests.test_m34_invariant_acrossCameraOps etc. as if they enforce keystone discipline. Test execution status is unknown;
  the atlas treats tests as living guarantors of invariants they may not assert and may not run. Class 8 (test scaffolding never executed).
                                                                                                                                                                                                                     
  F3.12 — panel.shadowPath is updated every frame, but is the BezierPath being recomputed?
                                                                                                                                                                                                                     
  SceneDelegate:90-93: panel.layer.shadowPath = UIBezierPath(roundedRect: panel.bounds, cornerRadius: cellCornerRadius).cgPath. A fresh UIBezierPath allocation every layout pass. During contraction, that's an
  allocation per frame at 120Hz. Memory churn. The atlas's F1 closure assumed this is performant; never measured. Class 4 (implicit performance contract).                                                           
  
  F3.13 — scalingSurface.layer.position manually set in layoutSubviews (CBSV:909-915) is brittle.                                                                                                                    
                                                            
  This works around Auto Layout not honoring anchorPoint = (0.5, 1.0) reliably. It's a private-API workaround in spirit. If UIKit's Auto Layout behavior changes (it has, in iOS 16 and 17), this manual position-set
   may conflict with framework-emitted writes. Class 4.                                                                                                                                                              
  
  ---                                                                                                                                                                                                                
  PERSONA 4 — The User Whose Finger Does Something Untested 
                                                                                                                                                                                                                     
  F4.1 — Pinch beginning at non-rest p (mid-gesture re-engagement) was never tested.
                                              
  Sandbox computes p = clamp(-log(scale)/logScaleSpan, 0, 1) per-event. UIPinchGestureRecognizer resets recognizer.scale = 1.0 at each new .began. If the user lifts mid-pinch at p=0.7 and starts a fresh pinch, the
   new pinch begins with scale=1.0 → p=0. The next event sets setProgress(0), snapping every subscriber back to chat-rest state. Visible snap. The atlas marked "active-cell binding lifecycle" as deferred but
  didn't enumerate THIS user case.                                                                                                                                                                                   
                                                                                                                                                                                                                     
  F4.2 — Centroid drift during pinch produces "anchored panel" feel.                                                                                                                                                 
                                                                                                                                                                                                                     
  SceneDelegate:340 ignores recognizer.location(in:). The panel does not follow the gesture centroid. If the user pinches around panel-bottom then drags fingers up, the panel stays put. Reads as anchored, not 
  held. The atlas's "the panel is in the user's grip" assumption was never verified against centroid motion.                                                                                                         
  
  F4.3 — Rapid repeated pinches have undefined cross-gesture state.                                                                                                                                                  
                                                            
  Sandbox has no debouncing. Pinch IN to p=0.7 → release → pinch OUT mid-decay. panel.heightConstraint.constant is at p=0.7's contracted value, not at p=0's natural. The next setProgress writes a new value, but   
  the constraint solver may interpolate (Auto Layout's implicit animation). Atlas claimed withSuppressedActions blocks implicit animation; only inside subscriber blocks, not around panel.heightConstraint.constant 
  = ... at SceneDelegate:252. Constraint mutation outside the suppressed block.
                                                                                                                                                                                                                     
  F4.4 — Pinch ending in hold beat freezes mid-state.       
                                                                                                                                                                                                                     
  User releases at p=0.48 (mid-hold). No commit logic exists (CF#7, but atlas tag-misassigned this as INTEGRATION). Panel sits at p=0.48 forever. Subscriber state is "mostly recede done, contraction not started,
  label invisible." User cannot tell whether they completed the gesture or not. Atlas treated this as integration concern only.                                                                                      
  
  F4.5 — Pinch starting from keyboard-up state breaks safeAreaH assumption.                                                                                                                                          
                                                            
  B2 deferred. But safeAreaH = viewportH - safeAreaTopInset - safeAreaBottomInset = 759 is hardcoded at SceneDelegate:67. If keyboard is up, real safeAreaH ≈ 509. CSV is sized to safeAreaH at sandbox boot. The    
  topFadeKnotsY (CSV-fraction y-values) re-anchor to a viewport that's 250pt taller than reality. Y-positions [y=40, 60, 100, 120] in the banked y-sampling no longer correspond to the same content positions.      
  
  F4.6 — Pinch outside panel bounds.                                                                                                                                                                                 
                                                            
  UIPinchGestureRecognizer is attached to view.view (not panel). Pinch starts on the gray gradient area below the panel. The recognizer fires; the panel shrinks; but the gesture centroid is in the gradient field, 
  far from the panel. User experience: "I pinched the empty space and the panel I wasn't touching shrank." Not a sandbox-only concern; the real app inherits this.                                                   
  
  F4.7 — Pinch + scroll simultaneity.                                                                                                                                                                                
                                                            
  The CSV contains a UIScrollView (bubbleStack's scroll). If the user begins a pinch with ANY vertical motion, the scroll recognizer may engage instead of (or in addition to) the pinch. Sandbox has no             
  UIGestureRecognizerDelegate.shouldRecognizeSimultaneouslyWith configuration. Untested.                                                                                                                             
  
  F4.8 — Pinch reversal exactly at p=0.50 (the secret-harmonic attractor).                                                                                                                                           
                                                            
  Wave 3 found the 0.50 attractor (4 channels meet at p=0.50). If the user's finger oscillates around 0.50 (slow, hand-tremor-magnitude), four channels switch on/off simultaneously per frame. Visual chatter at the
   joint hand-off. The matched-shoulder discipline assumes monotone p; oscillating p exposes the joint as a flicker locus. Atlas's "matched-span" closure verified continuous monotone sweep, not oscillating p.     
  
  F4.9 — Pinch + accessibility (Reduce Motion).                                                                                                                                                                      
                                                            
  The sandbox does not check UIAccessibility.isReduceMotionEnabled. For a user with Reduce Motion on, the smooth 1.5s sweep runs at full curve. Wave 4 said "Reduce-Motion: not a primitive concern; tag question."  
  But the gesture's CURVES are what Reduce Motion would gate. If primitive's curves don't have a Reduce-Motion path, the integration must add one — but the integration's reduce-motion path is for the MORPH
  animator (forward direction); the gesture itself doesn't have one. Primitive failure tag-misassigned again.
                                                                                                                                                                                                                     
  ---
  PERSONA 5 — The Synthesizer (Hidden Cross-Channel Dependencies)                                                                                                                                                    
                                                                 
  F5.1 — Panel bounds curve secretly conditions mask geometry.
                                              
  pinkMask.height = viewportH * 0.25 = 213pt (FIXED, SceneDelegate:213). panel.heightConstraint shrinks from viewportH to cellHeight=226. At p ≈ 0.55-0.60, panel.bottom rises through pinkMask.top. The pink area   
  between panel.bottom and pinkMask.top is REVEALED on the way up — not by pinkMask's recede curve, but by the panel un-occluding pink area mechanically. Pink and panel are geometrically coupled. Branch 5 noted
  "self-protective at p=1.0" but missed the SWEEP-THROUGH during contraction. Two channels share a hidden dependency NOT in the matched-shoulder pair.                                                               
                                                                                                                                                                                                                     
  F5.2 — cellBottomLift conditions far more than gradient extent.                                                                                                                                                    
                                                                                                                                                                                                                     
  Branch 11 named the cellBottomLift ↔ gradient stops triangle. Missed:
  - Shadow visibility — shadow renders below panel.bottom; if cellBottomLift is small, shadow falls into pinkMask zone and is occluded                                                                               
  - TopFadeBoundary's CSV-relative y mapping — CSV is bottom-anchored to panel-bottom; panel-bottom is determined by cellBottomLift   
  - dormantLabel center — label centered in panel; panel center moves with cellBottomLift                                                                                                                            
  - Mask edge collision — pinkMask.top at 75% viewport must be ≥ cell.bot (77.1%); 2.1pp margin
                                                                                                                                                                                                                     
  cellBottomLift is at the center of a hexagonal coupling, not a triangular one. Atlas surfaced one face.
                                                                                                                                                                                                                     
  F5.3 — dormantLabel reparenting + shadow shadowPath share the panel substrate.                                                                                                                                     
                                                                                                                                                                                                                     
  Both attach to panel. Shadow's shadowPath is computed from panel.bounds. dormantLabel.frame is INSIDE panel.bounds. The shadow rendering is independent of label content (shadowPath ignores subviews). But: at    
  p=0.85+, dormantLabel.alpha → 1 AND shadow.opacity → 1 simultaneously. The perceptual composite of "label fading in" and "shadow rising" produces a coupled visual event ("the label lands"). The atlas treats     
  these as independent channels with independent timing; the perceptual reading couples them. Channel-isolation principle (a) is violated at the perceptual layer.                                                   
                                                                                                                                                                                                                     
  F5.4 — dissolveFloor ↔ shadow's perceived contrast via shifting background.
                                                                                                                                                                                                                     
  Shadow renders BELOW panel.bottom into the substrate. The substrate changes color during gesture: pinkMask fades out p=0.50→0.65, exposing gradient pink underneath. The shadow's perceived contrast depends on the
   dynamically-changing background pink. The atlas's "0.06 opacity is whisper" was tuned at p=1.0 against a settled background. At p=0.85→0.95 (shadow's active range coinciding with contraction), the background is
   mid-transition. Whisper-perception may not survive against a changing background. F1's perceptual closure is calibration-narrow.
                                                                                                                                                                                                                     
  F5.5 — F1 (shadow) was tuned BEFORE F2 (texture), invalidating mid-contraction composite.
                                                                                                                                                                                                                     
  F1's "byte-identical pre/post" check at p=1.00 is for terminal state. During shadow's active range (p=0.85→1.0), the panel's INTERIOR is mid-dissolved (held-faint + body-out). F2 changed bubble spacing (4pt/16pt
   grouping), changing interior content density. Shadow was tuned against PRE-F2 interior; current (POST-F2) interior has different density → different perceptual contrast → whisper-perception may shift. The atlas
   claimed byte-identical at p=1.0 (which is true — at p=1.0, dormantLabel covers everything), but didn't check at p=0.90 (shadow active, interior still mid-dissolved).
                                                                                                                                                                                                                     
  F5.6 — scaleCurve ↔ topFadeKnotsY hidden coupling.        
                                                                                                                                                                                                                     
  topFadeKnotsY = [0.10, 0.167, 0.700, 0.833, 1.000] are CSV-FRACTION y-values. CSV is fixed-size. ScalingSurface inside CSV scales bodyContent from 1.0→0.40. Bubbles inside bodyContent shift relative to the 
  topFadeBoundary as scale changes. Knot K1 (CSV-fraction 0.167) was calibrated against bubble-B1 position at p=0; at p=0.40 (scale at floor), bubble-B1 is at a different CSV-relative y because bodyContent has
  shrunk. The cluster-then-hold shape relies on bubble positions at p=0; the shape is wrong at intermediate p. Atlas's "methodology punch-list" tagged the y-sampling as content-dependent but didn't surface the
  SCALE-DEPENDENT MOTION of bubbles relative to the fixed mask boundary.                                                                                                                                             
  
  F5.7 — Subscriber order is hidden contract on whose state THE CURVES depend.                                                                                                                                       
                                                            
  Branch 1 CF#2 noted order-insensitivity TODAY because no subscriber READS another's downstream effect. But the panel.heightConstraint write (External Subscriber #2 at SceneDelegate:252-254) writes BEFORE the 
  panel.shadowPath update (External Subscriber #4 at SceneDelegate:307-313, plus the viewDidLayoutSubviews-triggered shadowPath update). Order: heightConstraint changes → Auto Layout solves → viewDidLayoutSubviews
   fires → shadowPath recomputed → subscriber #4 writes shadowOpacity. If subscriber order changes, shadowPath may compute from stale bounds, then shadowOpacity sets against the new bounds. Visible mismatch. Order
   IS load-bearing; atlas declared it isn't.                                                                                                                                                                         
                                                            
  ---                                                                                                                                                                                                                
  PERSONA 6 — The Metacognitive Auditor Auditing the Auditor
                                                            
  F6.1 — Wave 4 over-attacked structurally, under-attacked perceptually.
                                              
  Wave 4's adversarial findings (K11 incompat, K13 reverse-tag, chatRestMarginFactor, harness phantom, CATransaction violation, arithmetic error) are all STRUCTURAL/LOGICAL. The user's prompt called for PERCEPTUAL
   attack ("user whose finger does something never tested"). Wave 4 reported the user's persona but did not generate the embarrassing-to-miss perceptual cases. Persona 4 above is the first time those cases are 
  taken seriously.                                                                                                                                                                                                   
                                                                                                                                                                                                                     
  F6.2 — Wave 4 named 15 absent principles (Branch 10) without weighting.                                                                                                                                            
                                                                                                                                                                                                                     
  The 15 absent principles vary wildly in consequence. "REVERSIBILITY as named invariant" is high-leverage (would directly catch the dissolve subscriber violation). "PRIMITIVE PORTABILITY TEST" is meta-leverage.
  "BREAKPOINT-TUNABLE BANK FORMAT" is bookkeeping. No ranking. A maintainer reading 15 absences doesn't know which to add first. Wave 4 inherited the list and did not prioritize.                                   
  
  F6.3 — Wave 4 attacked closures against gates, never attacked the gates themselves.                                                                                                                                
                                                            
  The atlas's gates are: mean luminance, p5, dark-coverage, contrast delta, extent percentage. Wave 4 noted "Δmean blindness" but did not enumerate WHAT THE RIGHT GATES would be for, e.g., "the panel feels like an
   object" (taste) or "the chrome lands" (rhythm). The atlas has no taxonomy of measurable-vs-perceptual properties. F1's taste-as-gate is the canonical failure of this absence.                                    
  
  F6.4 — The decomposition into 12 branches was unexamined.                                                                                                                                                          
                                                            
  The orchestrator dispatched 12 branches. Wave 4 audited what the branches found. Neither audited the choice of 12. A 13th branch — "perceptual phenomenology coupling" — would have surfaced findings in Persona 5 
  above. The atlas's decomposition itself is a bias surface. Trace's confidence is wave-completeness-bound; the wave count was the trace's choice.

  F6.5 — The trace was bias-toward-named-channels.                                                                                                                                                                   
                                          
  9 channels from the master spec were exhaustively traced. Un-named channels were under-traced:                                                                                                                     
  - Panel cornerRadius behavior during contraction (C3 closed; no curve)                                                                                                                                             
  - panel.shadowPath as continuous (treated as discrete, not as a curve-driven property)
  - The dormantBlur's effect field (UIBlurEffect intensity) — atlas notes blur scrubbing but never separates effect-as-set-once vs effect-as-curve                                                                   
                                                                                                                                                  
  F6.6 — Bias toward findability over importance.                                                                                                                                                                    
                                                            
  Phantom constants (CF-4: five named) are easy to find (grep unreferenced). Architectural incompatibility (K11) is hard to find (read CLAUDE.md vs code). Atlas reported the easy ones thoroughly; Wave 4 caught the
   hard one once. The ratio of attention is inversely proportional to importance.                                                                                                                                    
                                                                                                                                                                                                                     
  F6.7 — The atlas declared the trace itself as institutional memory and didn't establish exit protocol.                                                                                                             
                                                                                                                                                                                                                     
  Atlas's last action item is "Export this atlas to docs/ as ADR-style artifacts before the conversation ends." This is the most important recommendation. It was buried at item 12 of 12. If integration begins     
  without the export, the entire trace becomes conversation-only (Class 5 phantom). Priority inversion in the recommendation list itself.                                                                            
  
  ---                                                                                                                                                                                                                
  ATLAS v2 DIFF — What the audit changes                    
                                                                                                                                                                                                                     
  Structured Map additions/edits                            

  Node 1 (p-driver SSoT) — gains sub-finding:                                                                                                                                                                        
  - Subscriber order IS load-bearing across the heightConstraint→viewDidLayoutSubviews→shadowPath→shadowOpacity chain. Reclassify from "order-insensitive TODAY" to "order-coupled via Auto Layout side-effect chain"
   (F5.7).                                                                                                                                                                                                           
                                                                                                                                                                                                                     
  Node 1.4 (Pinch handler) — log mapping reclassified from PORTABLE to ENVIRONMENT-COUPLED:
  - Mapping presumes gesture begins at scale=1.0 origin (= chat-rest); real app begins at cell-rest. The mapping needs an origin-tracking wrapper to be portable (F1.1).                                             
                                                                                                                                                                        
  Node 4 (Track B contraction) — add coupling note:                                                                                                                                                                  
  - panel.bottom SWEEPS THROUGH pinkMask.top during contraction (F5.1). Pink reveal is partly geometric (panel un-occlusion) and partly curve-driven. Two channels share a dependency not in the matched-shoulder    
  pair.                                                                                                                                                                                                              
                                                                                                                                                                                                                     
  Node 5 (Gradient field) — add note on perceived-vs-measured shadow contrast:                                                                                                                                       
  - Shadow renders against a changing background (pinkMask fading p=0.50→0.65). F1's contrast measurement at terminal state may not survive against shifting substrate (F5.4).                                       
                                                                                                                                                                                                                     
  Node 7 (F1+F2+E2) — add F1-tuned-pre-F2 finding:                                                                                                                                                                   
  - F1 was tuned with PRE-F2 interior content density; F2 changed density via spacing; F1's whisper-perception is potentially miscalibrated for current (post-F2) interior (F5.5). Action: re-measure shadow         
  perceptual contrast at p=0.90 against post-F2 interior.                                                                                                                                                            
                                                                                                                                                                                                                     
  Node 8 (View hierarchy) — add invariants:                                                                                                                                                                          
  - (iv) UIBezierPath fresh allocation per layout pass (F3.12) — memory churn under contraction                                                                                                                      
  - (v) scalingSurface.layer.position manual set in layoutSubviews (CBSV:909-915) is anchor-workaround for Auto Layout — fragile under iOS minor version changes (F3.13)                                             
                                                                                                                                                                                                                     
  Node 11 (Deferred integration) — boundary expands to 7+ files:
  - Theme.swift, TimelineDataSource.swift, MorphTokens.swift added (F1.2). The "exactly 4 files" claim was undercounted by 75%.                                                                                      
                                                                                                                               
  New Node 13 — UNDOCUMENTED PERCEPTUAL COUPLINGS:                                                                                                                                                                   
  - dormantLabel-landing + shadow-rising perceptual event (F5.3)                                                                                                                                                     
  - topFadeKnotsY hold-fraction-of-CSV while bubbles scale (F5.6)                                                                                                                                                    
  - Shadow contrast against shifting pinkMask substrate (F5.4)                                                                                                                                                       
  - Pink reveal by panel un-occlusion + curve recede coupled (F5.1)                                                                                                                                                  
                                                                   
  New Node 14 — DEAD CODE / VESTIGIAL SUBSYSTEM:                                                                                                                                                                     
  - Self.sandboxMode = true flag with commented-out conditional (F3.1)                                                                                                                                               
  - 10-state demo schedule alongside pinch handler (F3.2)                                                                                                                                                            
  - debugReadout UILabel without DEBUG gate (F3.3)                                                                                                                                                                   
  - Original CBSV-side dormantLabel constraints (F3.6)                                                                                                                                                               
  - Subscriber writes during Track A on pinkMask/greyMask gradients (F3.7)                                                                                                                                           
  - /tmp/ F1 iteration files (F3.9)                                                                                                                                                                                  
  - Theme.Cell.fill ≠ Theme.Page.surface divergence (F3.4)                                                                                                                                                           
                                                                                                                                                                                                                     
  Consequence Narrative additions             
                                                                                                                                                                                                                     
  Add to the consequence-thread section:                                                                                                                                                                             
                                                                                                                                                                                                                     
  The maintenance fragility chain. The atlas's institutional memory is conversation-bound; the export protocol is item 12 of 12 (F6.7). The harness is phantom; the dial-back iteration files live in /tmp (F3.9);   
  the sweep_* directories' git status is unknown (F3.8); the reference video provenance is unstated (F2.1). Four layers of artifact volatility stack: conversation → harness → iteration artifacts → reference. Each 
  layer is independently lossy. The atlas's "the atlas IS the institutional memory" assertion becomes "the atlas is the only-and-fragile institutional memory" once the layers are enumerated. Two-year maintainer
  has zero recoverability.                                                                                                                                                                                           
                                                            
  The perceptual-coupling cascade. Channels were traced in isolation per the wave decomposition (12 branches, one per named channel + meta). The synthesizer persona finds at least 4 cross-channel couplings that no
   branch was tasked to surface (F5.1, F5.3, F5.4, F5.6). The atlas's "9 concurrent channels" framing (principle a) is correct as a tuning posture but wrong as an isolation claim — channels couple PERCEPTUALLY
  even when their measured signatures decouple. The atlas's confidence ("composite mean ≈ 225 verified") is order-blind to perceptual-character couplings.
                                                                                                                                                                                                                     
  Heat Map Summary additions                  
                                                                                                                                                                                                                     
  Add to keystone list:                                     
                                                                                                                                                                                                                     
  Keystone 6 — Subscriber order via Auto Layout side-effect chain. Removing the implicit order (heightConstraint→viewDidLayoutSubviews→shadowPath→shadowOpacity) breaks shadow alignment under any subscriber
  reordering. Not declared as load-bearing in subscribe()/setProgress() contract.                                                                                                                                    
                                                            
  Add to critical findings:                                                                                                                                                                                          
  
  - Boundary undercounted (4 files claimed, 7+ actual)                                                                                                                                                               
  - Reference video provenance undocumented                 
  - F1 tuned PRE-F2; whisper-perception unverified against current interior
  - Pink reveal coupled to panel un-occlusion geometry (not just pink curve)                                                                                                                                         
  - subscriber order is load-bearing despite atlas's "order-insensitive today" claim
  - Theme.Cell.fill ≠ Theme.Page.surface (sandbox vs integration color divergence)                                                                                                                                   
  - /tmp/ F1 iteration artifacts already-or-imminently lost                                                                                                                                                          
  - sandboxMode flag's commented conditional is dead code                                                                                                                                                            
                                                                                                                                                                                                                     
  Add to blind spots (Wave 4 found these; Wave 4 hunt 2 finds more):                                                                                                                                                 
                                                                                                                                                                                                                     
  - Pinch + UIScrollView simultaneity (F4.7)                                                                                                                                                                         
  - Pinch reversal exactly at the 0.50 attractor (F4.8)                                                                                                                                                              
  - Centroid drift during pinch (F4.2)                      
  - Rapid repeated pinches (F4.3)                                                                                                                                                                                    
  - Pinch ending in hold beat (F4.4)                        
  - Pinch from keyboard-up safeAreaH (F4.5)                                                                                                                                                                          
  - Pinch outside panel bounds (F4.6)                                                                                                                                                                                
  - Pinch + Reduce Motion (F4.9; tag-misassignment of accessibility)
                                                                                                                                                                                                                     
  Add to frontiers:                                                                                                                                                                                                  
                                                                                                                                                                                                                     
  - Subscriber order audit (formal proof of order-irrelevance OR enumerate dependencies)                                                                                                                             
  - Pre-F2 vs post-F2 shadow contrast re-measurement        
  - Reference video provenance documentation                                                                                                                                                                         
  - Atlas export pipeline (Wave 4's recommendation 10 promoted to priority 1)                                                                                                                                        
  - Re-evaluation of "channels are isolated" claim against perceptual-coupling findings (Persona 5)
                                                                                                                                                                                                                     
  Acceptance criteria revision                                                                                                                                                                                       
                                                                                                                                                                                                                     
  Wave 4 reported all 8 acceptance criteria as ✅. This audit downgrades:                                                                                                                                            
                                                                                                                                                                                                                     
  ┌───────────────────────────────────────────────────────────────────────────┬──────────────┬───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
  │                                 Criterion                                 │   Wave 4     │                                                 Post-audit status                                                 │   
  │                                                                           │    status    │                                                                                                                   │
  ├───────────────────────────────────────────────────────────────────────────┼──────────────┼───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤   
  │ Every tuned constant has PORTABLE/COUPLED/REPLACED with environmental     │ ✅           │ DOWNGRADED — log-pinch mapping was PORTABLE without origin proof (F1.1); Theme.Cell.fill divergence missed (F3.4) │
  │ dependency                                                                │              │                                                                                                                   │
  ├───────────────────────────────────────────────────────────────────────────┼──────────────┼───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ Every INTEGRATION-tagged item has seam map                                │ ✅           │ DOWNGRADED — 4-file boundary undercounted by 75%; Theme.swift, TimelineDataSource.swift, MorphTokens.swift        │
  │                                                                           │              │ unaddressed (F1.2)                                                                                                │   
  ├───────────────────────────────────────────────────────────────────────────┼──────────────┼───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ Every Q6 absence classified                                               │ ✅           │ DOWNGRADED — at least 8 specific user-finger cases (F4.1-F4.9) not in absence list                                │   
  ├───────────────────────────────────────────────────────────────────────────┼──────────────┼───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤   
  │ Phantom hunt covers 10 classes                                            │ ✅           │ DOWNGRADED — 13 new phantoms found (F3.1-F3.13); Wave 4 underreported                                             │
  ├───────────────────────────────────────────────────────────────────────────┼──────────────┼───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤   
  │ Closed-item verification context documented                               │ ✅           │ DOWNGRADED — reference video provenance unstated (F2.1); /tmp artifacts uncaptured (F3.9); sweep_* git status     │   
  │                                                                           │              │ unstated (F3.8)                                                                                                   │
  └───────────────────────────────────────────────────────────────────────────┴──────────────┴───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘   
                                                            
  Five of eight criteria fall after the audit. Three (keystones, adversarial-produced-findings, synthesis-identified-bedrock) survive.                                                                               
                                                            
  ---                                                                                                                                                                                                                
  Final disposition                                                                                                                                                                                                  
                   
  The user warned: "If the adversarial pass changed nothing, it failed." This pass produced:                                                                                                                         
                                                            
  - 6 personas × ~5-13 concrete findings each = ~50 new findings with file:line references (F1.1-F1.6, F2.1-F2.7, F3.1-F3.13, F4.1-F4.9, F5.1-F5.7, F6.1-F6.7)
  - Atlas diff with edits to Nodes 1, 1.4, 4, 5, 7, 8, 11 + two new Nodes (13 perceptual-couplings, 14 dead-code/vestigial)
  - 3 keystones-list additions + 8 new critical findings + 8 new blind spots + 5 new frontiers                                                                                                                       
  - 5 of 8 acceptance criteria downgraded                                                                                                                                                                            
                                                                                                                                                                                                                     
  The audit changed the atlas. The most consequential single shift: the boundary undercount (4 → 7+ files) plus the subscriber order load-bearing finding plus the perceptual-coupling cascade collectively mean     
  Atlas #2 cannot use Atlas #1 as a closed input — Atlas #2 must integrate against the audit-revised state, not against the pre-audit state.                                                                         
                                                                                                                                                                                                                     
  Honest residue. This pass did not exhaust:                                                                                                                                                                         
  - The hardcoded shadowPath BezierPath allocation per-frame (F3.12) — not measured for production perf
  - The Tests/V2/* test execution status (F3.11) — not verified                                                                                                                                                      
  - The "F1 was tuned PRE-F2" perceptual claim (F5.5) — hypothetical until re-measured against post-F2 interior                                                                                                      
  - The reference video provenance (F2.1) — recoverable only by asking the human                    

