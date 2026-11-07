// Curated OsmAnd region tokens for the Maps picker (#188). A common-cases subset:
// continents, major countries, and all 50 US states. The picker's free-text box accepts
// any other OsmAnd token (the installers pass unknown region names straight through).
// Tokens here match what get-offline-library.sh --region / -Region accept.
window.REGIONS = {
  continents: [
    { "token": "northamerica", "label": "North America", "countries": [
      { "token": "US", "label": "United States", "subregions": [
        { "token": "US_alabama", "label": "Alabama" },
        { "token": "US_alaska", "label": "Alaska" },
        { "token": "US_arizona", "label": "Arizona" },
        { "token": "US_arkansas", "label": "Arkansas" },
        { "token": "US_california", "label": "California" },
        { "token": "US_colorado", "label": "Colorado" },
        { "token": "US_connecticut", "label": "Connecticut" },
        { "token": "US_delaware", "label": "Delaware" },
        { "token": "US_florida", "label": "Florida" },
        { "token": "US_georgia", "label": "Georgia" },
        { "token": "US_hawaii", "label": "Hawaii" },
        { "token": "US_idaho", "label": "Idaho" },
        { "token": "US_illinois", "label": "Illinois" },
        { "token": "US_indiana", "label": "Indiana" },
        { "token": "US_iowa", "label": "Iowa" },
        { "token": "US_kansas", "label": "Kansas" },
        { "token": "US_kentucky", "label": "Kentucky" },
        { "token": "US_louisiana", "label": "Louisiana" },
        { "token": "US_maine", "label": "Maine" },
        { "token": "US_maryland", "label": "Maryland" },
        { "token": "US_massachusetts", "label": "Massachusetts" },
        { "token": "US_michigan", "label": "Michigan" },
        { "token": "US_minnesota", "label": "Minnesota" },
        { "token": "US_mississippi", "label": "Mississippi" },
        { "token": "US_missouri", "label": "Missouri" },
        { "token": "US_montana", "label": "Montana" },
        { "token": "US_nebraska", "label": "Nebraska" },
        { "token": "US_nevada", "label": "Nevada" },
        { "token": "US_new-hampshire", "label": "New Hampshire" },
        { "token": "US_new-jersey", "label": "New Jersey" },
        { "token": "US_new-mexico", "label": "New Mexico" },
        { "token": "US_new-york", "label": "New York" },
        { "token": "US_north-carolina", "label": "North Carolina" },
        { "token": "US_north-dakota", "label": "North Dakota" },
        { "token": "US_ohio", "label": "Ohio" },
        { "token": "US_oklahoma", "label": "Oklahoma" },
        { "token": "US_oregon", "label": "Oregon" },
        { "token": "US_pennsylvania", "label": "Pennsylvania" },
        { "token": "US_rhode-island", "label": "Rhode Island" },
        { "token": "US_south-carolina", "label": "South Carolina" },
        { "token": "US_south-dakota", "label": "South Dakota" },
        { "token": "US_tennessee", "label": "Tennessee" },
        { "token": "US_texas", "label": "Texas" },
        { "token": "US_utah", "label": "Utah" },
        { "token": "US_vermont", "label": "Vermont" },
        { "token": "US_virginia", "label": "Virginia" },
        { "token": "US_washington", "label": "Washington" },
        { "token": "US_west-virginia", "label": "West Virginia" },
        { "token": "US_wisconsin", "label": "Wisconsin" },
        { "token": "US_wyoming", "label": "Wyoming" },
      ] },
      { "token": "Canada", "label": "Canada" },
      { "token": "Mexico", "label": "Mexico" }
    ] },
    { "token": "centralamerica", "label": "Central America", "countries": [
      { "token": "Costa-Rica", "label": "Costa Rica" },
      { "token": "Guatemala", "label": "Guatemala" },
      { "token": "Panama", "label": "Panama" }
    ] },
    { "token": "southamerica", "label": "South America", "countries": [
      { "token": "Brazil", "label": "Brazil" },
      { "token": "Argentina", "label": "Argentina" },
      { "token": "Chile", "label": "Chile" },
      { "token": "Colombia", "label": "Colombia" },
      { "token": "Peru", "label": "Peru" }
    ] },
    { "token": "europe", "label": "Europe", "countries": [
      { "token": "Gb", "label": "United Kingdom" },
      { "token": "Ireland", "label": "Ireland" },
      { "token": "France", "label": "France" },
      { "token": "Germany", "label": "Germany" },
      { "token": "Spain", "label": "Spain" },
      { "token": "Portugal", "label": "Portugal" },
      { "token": "Italy", "label": "Italy" },
      { "token": "Netherlands", "label": "Netherlands" },
      { "token": "Belgium", "label": "Belgium" },
      { "token": "Switzerland", "label": "Switzerland" },
      { "token": "Austria", "label": "Austria" },
      { "token": "Poland", "label": "Poland" },
      { "token": "Sweden", "label": "Sweden" },
      { "token": "Norway", "label": "Norway" },
      { "token": "Finland", "label": "Finland" },
      { "token": "Denmark", "label": "Denmark" },
      { "token": "Greece", "label": "Greece" },
      { "token": "Ukraine", "label": "Ukraine" }
    ] },
    { "token": "africa", "label": "Africa", "countries": [
      { "token": "South-Africa", "label": "South Africa" },
      { "token": "Kenya", "label": "Kenya" },
      { "token": "Nigeria", "label": "Nigeria" },
      { "token": "Egypt", "label": "Egypt" },
      { "token": "Morocco", "label": "Morocco" }
    ] },
    { "token": "asia", "label": "Asia", "countries": [
      { "token": "Japan", "label": "Japan" },
      { "token": "India", "label": "India" },
      { "token": "Indonesia", "label": "Indonesia" },
      { "token": "Philippines", "label": "Philippines" },
      { "token": "Turkey", "label": "Turkey" },
      { "token": "United-Arab-Emirates", "label": "United Arab Emirates" }
    ] },
    { "token": "australia-oceania", "label": "Australia & Oceania", "countries": [
      { "token": "Australia", "label": "Australia" },
      { "token": "New-Zealand", "label": "New Zealand" }
    ] }
  ]
};
