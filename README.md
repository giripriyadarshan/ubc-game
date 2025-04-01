# Advanced Game Design Project Concept Demo
Ultimate Bar Championship

<img src="./Assets/ubc-logo.png" alt="Alt Text" width="512px" height="auto">

2D PvP Beat Em Up Game design concept demo for college project. Developed using <img src="https://avatars.githubusercontent.com/u/6318500" alt="Alt Text" width="16px" height="auto">Godot engine

Overview:
- **Player Skills**: Punch, Block, Trash Talk
- **Player Stats**: Health, Endurance
- **Resources**: Beer, Whiskey, Time
- **Opponent**: Opponent Skill, Opponent Health
- **Combat Mechanics**: Simultaneous punch, Skill effects on stats
- **Outcome**: Health, Opponent Health
- **Recovery Mechanics**: Time, Endurance
- **Stat effects on skills**: Health, Endurance
- **Resource relationships**: Beer, Whiskey
- **Time costs**: Punch, Block, Trash Talk

<details>
<summary>Resource Diagram</summary>

```mermaid
---
config:
  layout: elk
---
flowchart TD
    %% Main node definitions
    Result[["RESULT"]]:::outcome
    
    %% Subgraph for Player Skills
    subgraph PlayerSkills ["PLAYER SKILLS"]
        direction TB
        Punch("Punch"):::playerSkill
        Block("Block"):::playerSkill
        TrashTalk("Trash Talk"):::playerSkill
    end
    
    %% Subgraph for Player Stats
    subgraph PlayerStats ["PLAYER STATS"]
        direction LR
        Health((("Health"))):::stat
        Endurance("Endurance"):::stat
    end
    
    %% Subgraph for Resources
    subgraph Resources ["RESOURCES"]
        direction TB
        Beer("Beer"):::resource
        Whiskey("Whiskey"):::resource
        Time("Time"):::resource
    end
    
    %% Subgraph for Opponent
    subgraph Opponent ["OPPONENT"]
        OpponentSkill("Opponent Skill"):::playerSkill
        OpponentHealth("Opponent Health"):::stat
    end
    
    %% Skill effects on stats
    Punch -->|"Deals damage"| OpponentHealth
    Punch -->|"Drains"| Endurance
    Block -->|"Prevents damage"| Health
    Block -->|"Builds"| Endurance
    TrashTalk -->|"Disrupts"| OpponentSkill
    
    %% Resource relationships
    Punch -->|"Rewards"| Beer
    Block -->|"Rewards"| Whiskey
    Beer -->|"Restores"| Health
    Whiskey -->|"Boosts"| Endurance
    
    %% Time costs
    Punch -->|"Costs"| Time
    Block -->|"Costs"| Time
    TrashTalk -->|"Costs"| Time
    Beer -->|"Takes time to drink"| Time
    Whiskey -->|"Takes time to drink"| Time
    
    %% Combat mechanics
    Punch <-->|"Simultaneous punch"| OpponentSkill
    
    %% Outcome relationships
    Health -->|"Determines"| Result
    OpponentHealth -->|"Affects"| Result
    
    %% Recovery mechanics
    Time -->|"Recovers over time"| Endurance
    
    %% Stat effects on skills
    Health -->|"Enables"| PlayerSkills
    Endurance -->|"Powers"| PlayerSkills
    
    %% Style definitions
    classDef playerSkill fill:#d4f1f9,stroke:#0077b6,stroke-width:2px,border-radius:8px
    classDef resource fill:#ffe6cc,stroke:#ff9900,stroke-width:2px,border-radius:8px
    classDef stat fill:#d5e8d4,stroke:#82b366,stroke-width:2px,border-radius:8px
    classDef outcome fill:#e1d5e7,stroke:#9673a6,stroke-width:3px,border-radius:8px,font-weight:bold
    
    %% Subgraph styling
    style PlayerSkills fill:#f0f8ff,stroke:#0077b6,stroke-width:1px
    style PlayerStats fill:#f0fff0,stroke:#82b366,stroke-width:1px
    style Resources fill:#fff8f0,stroke:#ff9900,stroke-width:1px
    style Opponent fill:#fff0f0,stroke:#cc0000,stroke-width:1px
```
</details>