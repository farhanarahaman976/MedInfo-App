const medicines = [
  {
    id: 1,
    name: "Paracetamol",
    category: "Analgesic",
    description: "Paracetamol is used to relieve mild to moderate pain and reduce fever.",
    uses: ["Headache", "Fever", "Muscle pain"],
    dosage: "Typically 500 mg every 4-6 hours as needed.",
  },
  {
    id: 2,
    name: "Amoxicillin",
    category: "Antibiotic",
    description: "Amoxicillin is a penicillin antibiotic used to treat infections caused by bacteria.",
    uses: ["Ear infection", "Sinus infection", "Respiratory infection"],
    dosage: "Usually 250-500 mg every 8 hours depending on severity.",
  },
  {
    id: 3,
    name: "Cetirizine",
    category: "Antihistamine",
    description: "Cetirizine is used to relieve allergy symptoms such as sneezing and itching.",
    uses: ["Hay fever", "Allergic rhinitis", "Skin rash"],
    dosage: "10 mg once daily, typically in the morning or evening.",
  },
  {
    id: 4,
    name: "Aspirin",
    category: "Analgesic",
    description: "Aspirin reduces pain, fever, and inflammation and may help prevent blood clots.",
    uses: ["Headache", "Inflammation", "Heart attack prevention"],
    dosage: "300-600 mg every 4-6 hours, not exceeding 4 g per day.",
  },
];

const medicineList = document.getElementById("medicine-list");
const searchInput = document.getElementById("search");
const categoryFilter = document.getElementById("category-filter");

function getCategories() {
  const categories = medicines.map((item) => item.category);
  return ["All categories", ...new Set(categories)];
}

function renderCategories() {
  const categories = getCategories();
  categoryFilter.innerHTML = categories
    .map(
      (category) => `
      <option value="${category}">${category}</option>`
    )
    .join("");
}

function buildCard(medicine) {
  return `
    <article class="card">
      <h2>${medicine.name}</h2>
      <div class="meta">${medicine.category}</div>
      <p>${medicine.description}</p>
      <p><strong>Dosage:</strong> ${medicine.dosage}</p>
      <ul>
        ${medicine.uses.map((use) => `<li>${use}</li>`).join("")}
      </ul>
    </article>
  `;
}

function renderMedicines(items) {
  if (!items.length) {
    medicineList.innerHTML = "<p>No medicines found. Try a different keyword or category.</p>";
    return;
  }
  medicineList.innerHTML = items.map(buildCard).join("");
}

function filterMedicines() {
  const searchTerm = searchInput.value.trim().toLowerCase();
  const selectedCategory = categoryFilter.value;

  const filtered = medicines.filter((medicine) => {
    const matchesSearch =
      medicine.name.toLowerCase().includes(searchTerm) ||
      medicine.description.toLowerCase().includes(searchTerm) ||
      medicine.uses.some((item) => item.toLowerCase().includes(searchTerm));

    const matchesCategory =
      selectedCategory === "All categories" || medicine.category === selectedCategory;

    return matchesSearch && matchesCategory;
  });

  renderMedicines(filtered);
}

searchInput.addEventListener("input", filterMedicines);
categoryFilter.addEventListener("change", filterMedicines);

renderCategories();
renderMedicines(medicines);
