import net from "net";
import React, { useEffect, useState } from "react";
import "./App.css";

import { match, __ } from "ts-pattern";
import { Option, Some, None, Result, Ok, Err } from "ts-results";

class StatSet {
  private hp: number;
  private attack: number;
  private defense: number;
  private specialAttack: number;
  private specialDefense: number;
  private speed: number;

  constructor(
    hp: number, attack: number, defense: number, specialAttack: number,
    specialDefense: number, speed: number
  ) {
    this.hp = hp;
    this.attack = attack;
    this.defense = defense;
    this.specialAttack = specialAttack;
    this.specialDefense = specialDefense;
    this.speed = speed;
  }

  public getHp(): number {
    return this.hp;
  }

  public getAttack(): number {
    return this.attack;
  }

  public getDefense(): number {
    return this.defense;
  }

  public getSpecialAttack(): number {
    return this.specialAttack;
  }

  public getSpecialDefense(): number {
    return this.specialDefense;
  }

  public getSpeed(): number {
    return this.speed;
  }
}

class Pokemon {
  private nationalId: number;
  private species: string;
  private otId: string;
  private otSid: string;
  private xp: number;
  private item: string;
  private pokerus: boolean;
  private friendship: number;
  private ability: string;
  private moves: string[];
  private ivs: StatSet;
  private evs: StatSet;
  private stats: StatSet;
  private currentHp: number;

  constructor(
    nationalId: number, species: string, otId: string, otSid: string,
    xp: number, item: string, pokerus: boolean, friendship: number,
    ability: string, moves: string[], ivs: StatSet, evs: StatSet,
    stats: StatSet, currentHp: number
  ) {
    this.nationalId = nationalId;
    this.species = species;
    this.otId = otId;
    this.otSid = otSid;
    this.xp = xp;
    this.item = item;
    this.pokerus = pokerus;
    this.friendship = friendship;
    this.ability = ability;
    this.moves = moves;
    this.ivs = ivs;
    this.evs = evs;
    this.stats = stats;
    this.currentHp = currentHp;
  }

  public getNationalId(): number {
    return this.nationalId;
  }

  public getSpecies(): string {
    return this.species;
  }

  public getOtId(): string {
    return this.otId;
  }

  public getOtSid(): string {
    return this.otSid;
  }

  public getXp(): number {
    return this.xp;
  }

  public getItem(): string {
    return this.item;
  }

  public getPokerus(): boolean {
    return this.pokerus;
  }

  public getFriendship(): number {
    return this.friendship;
  }

  public getAbility(): string {
    return this.ability;
  }

  public getMoves(): string[] {
    return this.moves;
  }

  public getIvs(): StatSet {
    return this.ivs;
  }

  public getEvs(): StatSet {
    return this.evs;
  }

  public getStats(): StatSet {
    return this.stats;
  }

  public getCurrentHp(): number {
    return this.currentHp;
  }
}

const App = () => {

  /* I don't think I'll need all this, but I'll keep it in case we want some
   * fancy on-click effects at some point.
  let [rButton, setRButton] = useState(false);
  let [lButton, setLButton] = useState(false);
  let [xButton, setXButton] = useState(false);
  let [yButton, setYButton] = useState(false);
  let [aButton, setAButton] = useState(false);
  let [bButton, setBButton] = useState(false);
  let [startButton, setStartButton] = useState(false);
  let [selectButton, setSelectButton] = useState(false);
  let [upButton, setUpButton] = useState(false);
  let [downButton, setDownButton] = useState(false);
  let [leftButton, setLeftButton] = useState(false);
  let [rightbutton, setRightButton] = useState(false);
  */

  let [team, setTeam] = useState([] as Pokemon[])

  // If you set this to a much lower tick rate, the API slows down pretty bad.
  // self-DDOSing lol
  const TICKRATE: number = 1000;

  useEffect(() => {
    const interval = setInterval(() => {
      // https://stackoverflow.com/a/43540056 for basic response parsing.
      fetch("http://localhost:8000/api/team")
        .then((response) => response.text())
        .then((json) => {
          let parsed: { [key: string]: any } = JSON.parse(json);
          if (parsed?.is_ok == true) {
            let team: Pokemon[] = []
            for (let pokemon of parsed?.val) {
              team.push(
                new Pokemon(
                  pokemon["national_id"],
                  pokemon["species"],
                  pokemon["ot_id"],
                  pokemon["ot_sid"],
                  pokemon["xp"],
                  pokemon["item"],
                  pokemon["pokerus"],
                  pokemon["friendship"],
                  pokemon["ability"],
                  pokemon["moves"],
                  new StatSet(
                    pokemon["ivs"]["hp"],
                    pokemon["ivs"]["attack"],
                    pokemon["ivs"]["defense"],
                    pokemon["ivs"]["special_attack"],
                    pokemon["ivs"]["special_defense"],
                    pokemon["ivs"]["speed"]
                  ),
                  new StatSet(
                    pokemon["evs"]["hp"],
                    pokemon["evs"]["attack"],
                    pokemon["evs"]["defense"],
                    pokemon["evs"]["special_attack"],
                    pokemon["evs"]["special_defense"],
                    pokemon["evs"]["speed"]
                  ),
                  new StatSet(
                    pokemon["stats"]["hp"],
                    pokemon["stats"]["attack"],
                    pokemon["stats"]["defense"],
                    pokemon["stats"]["special_attack"],
                    pokemon["stats"]["special_defense"],
                    pokemon["stats"]["speed"]
                  ),
                  pokemon["current_hp"]
                )
              );
            }
            setTeam(team);
          } else {

          }
        })
        .catch((error) => {
          console.log("An error occurred: " + error);
        })
    }, TICKRATE);

    return () => clearInterval(interval);
  }, []);

  function renderPokemon(pokemon: Pokemon): JSX.Element {
    let hpPercentage: string =
      String((pokemon.getCurrentHp() / pokemon.getStats().getHp()) * 100) + "%";
    let hpBarStyle = {
      width: hpPercentage
    };
    return (
      <div className="pokemon">
        <div className="pokemon-top">

        </div>
        <div className="pokemon-bot">
          <div className="pokemon-status">
            <div className="pokemon-status-col">
              <div className="pokemon-name">{pokemon.getSpecies()}</div>
              <div className="pokemon-level">
                <strong>Lv.</strong>
                N/A
              </div>
            </div>
            <div className="pokemon-status-col">
              <div className="pokemon-hp">
                <strong>HP:</strong>
                {pokemon.getCurrentHp()}/{pokemon.getStats().getHp()}
              </div>
              <div className="pokemon-hp-bar">
                <div className="bar" style={hpBarStyle}></div>
              </div>
            </div>
          </div>
          <div className="pokemon-ability">
            <strong>Ability: </strong>
            {pokemon.getAbility()}
          </div>
          <div className="pokemon-item">
            <strong>Item: </strong>
            {pokemon.getItem()}
          </div>
        </div>
      </div>
    );
  }

  function renderTeam(team: Pokemon[]): JSX.Element {
    return (
      <div className="team">
        {team.map(p => renderPokemon(p))}
      </div>
    );
  }

  // Could change this to rely on enumerations later but might just be best to
  // just roll with this, it at least works.
  function pressButton(button: string): void {
    fetch("http://localhost:8000/api/press/" + button)
      .then((response) => response.text())
      .then((json) => {
        let parsed: { [key: string]: any } = JSON.parse(json);
        if (parsed?.is_ok == false) {
          console.log("An error happened while attempting to press " + button + ": " + parsed?.val);
        }
      })
      .catch((error) => {
        console.log("An error occurred: " + error);
      });
  }

  function releaseButton(button: string): void {
    fetch("http://localhost:8000/api/release/" + button)
      .then((response) => response.text())
      .then((json) => {
        let parsed: { [key: string]: any } = JSON.parse(json);
        if (parsed?.is_ok == false) {
          console.log("An error happened while attempting to release " + button + ": " + parsed?.val);
        }
      })
      .catch((error) => {
        console.log("An error occurred: " + error);
      });
  }

  function render(): JSX.Element {
    return (
      <div className="App">
        {renderTeam(team)}
        <div className="controls">
          <div className="controls-triggers">
            <button
              className="controls-trigger"
              onMouseDown={ () => pressButton("L") }
              onMouseUp={ () => releaseButton("L") }
            >
              L
            </button>
            <button
              className="controls-trigger"
              onMouseDown={ () => pressButton("R") }
              onMouseUp={ () => releaseButton("R") }
            >
              R
            </button>
          </div>
          <div className="controls-dpad">
            <button
              className="controls-button"
              onMouseDown={ () => pressButton("up") }
              onMouseUp={ () => releaseButton("up") }
            >
              Up
            </button>
            <button
              className="controls-button"
              onMouseDown={ () => pressButton("down") }
              onMouseUp={ () => releaseButton("down") }
            >
              Down
            </button>
            <button
              className="controls-button"
              onMouseDown={ () => pressButton("left") }
              onMouseUp={ () => releaseButton("left") }
            >
              Left
            </button>
            <button
              className="controls-button"
              onMouseDown={ () => pressButton("right") }
              onMouseUp={ () => releaseButton("right") }
            >
              Right
            </button>
          </div>
          <div className="controls-face">
            <button
              className="controls-button"
              onMouseDown={ () => pressButton("X") }
              onMouseUp={ () => releaseButton("X") }
            >
              X
            </button>
            <button
              className="controls-button"
              onMouseDown={ () => pressButton("Y") }
              onMouseUp={ () => releaseButton("Y") }
            >
              Y
            </button>
            <button
              className="controls-button"
              onMouseDown={ () => pressButton("A") }
              onMouseUp={ () => releaseButton("A") }
            >
              A
            </button>
            <button
              className="controls-button"
              onMouseDown={ () => pressButton("B") }
              onMouseUp={ () => releaseButton("B") }
            >
              B
            </button>
          </div>
          <div className="controls-options">
            <button
              className="controls-button"
              onMouseDown={ () => pressButton("start") }
              onMouseUp={ () => releaseButton("start") }
            >
              Start
            </button>
            <button
              className="controls-button"
              onMouseDown={ () => pressButton("select") }
              onMouseUp={ () => releaseButton("select") }
            >
              Select
            </button>
          </div>
        </div>
      </div>
    );
  }

  return render();
}

export default App;
