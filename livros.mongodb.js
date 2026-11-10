// =====================================================================
// Trabalho: Banco de dados NoSQL (MongoDB) - Acervo de Livros
// Operacoes: criacao do banco, da colecao, insercao e CRUD completo
// Como executar: mongosh "<URI>" --file livros.mongodb.js
//                ou colar bloco por bloco no MongoDB Compass / mongosh
// =====================================================================

// ---------------------------------------------------------------------
// 1. CRIACAO DO BANCO DE DADOS
// No MongoDB o banco passa a existir de fato quando recebe o primeiro
// documento; o comando "use" apenas seleciona o contexto.
// ---------------------------------------------------------------------
use("biblioteca");

// ---------------------------------------------------------------------
// 2. CRIACAO DA COLECAO
// Colecao = equivalente a "tabela" no modelo relacional.
// O drop() inicial deixa o script reexecutavel sem duplicar dados.
// ---------------------------------------------------------------------
db.livros.drop();
db.createCollection("livros");

// ---------------------------------------------------------------------
// 3. CREATE - insercao de 5 livros
// Campos: titulo, autor, ano, categorias, editora, paginas,
//         disponivel, avaliacao
// ---------------------------------------------------------------------
db.livros.insertMany([
  {
    titulo: "Dom Casmurro",
    autor: "Machado de Assis",
    ano: 1899,
    categorias: ["Romance", "Literatura Brasileira", "Classico"],
    editora: "Livraria Garnier",
    paginas: 256,
    disponivel: true,
    avaliacao: 4.7
  },
  {
    titulo: "O Cortico",
    autor: "Aluisio Azevedo",
    ano: 1890,
    categorias: ["Naturalismo", "Literatura Brasileira"],
    editora: "Editora Martin Claret",
    paginas: 304,
    disponivel: true,
    avaliacao: 4.3
  },
  {
    titulo: "1984",
    autor: "George Orwell",
    ano: 1949,
    categorias: ["Ficcao Cientifica", "Distopia", "Politica"],
    editora: "Companhia das Letras",
    paginas: 416,
    disponivel: false,
    avaliacao: 4.9
  },
  {
    titulo: "O Senhor dos Aneis: A Sociedade do Anel",
    autor: "J. R. R. Tolkien",
    ano: 1954,
    categorias: ["Fantasia", "Aventura"],
    editora: "HarperCollins",
    paginas: 576,
    disponivel: true,
    avaliacao: 4.8
  },
  {
    titulo: "Clean Code",
    autor: "Robert C. Martin",
    ano: 2008,
    categorias: ["Tecnologia", "Engenharia de Software"],
    editora: "Prentice Hall",
    paginas: 464,
    disponivel: false,
    avaliacao: 4.6
  }
]);

print("--- 3. CREATE: total de livros inseridos ---");
printjson(db.livros.countDocuments());

// ---------------------------------------------------------------------
// 4. READ - consultas
// ---------------------------------------------------------------------

// 4.1 Todos os livros
print("--- 4.1 READ: todos os livros ---");
db.livros.find().forEach(printjson);

// 4.2 Filtro por igualdade: apenas os disponiveis
print("--- 4.2 READ: livros disponiveis ---");
db.livros.find({ disponivel: true }, { titulo: 1, autor: 1, _id: 0 }).forEach(printjson);

// 4.3 Operador de comparacao: publicados a partir de 1950
print("--- 4.3 READ: publicados a partir de 1950 ---");
db.livros.find({ ano: { $gte: 1950 } }, { titulo: 1, ano: 1, _id: 0 }).forEach(printjson);

// 4.4 Busca dentro de array: categoria "Fantasia"
print("--- 4.4 READ: categoria Fantasia ---");
db.livros.find({ categorias: "Fantasia" }, { titulo: 1, categorias: 1, _id: 0 }).forEach(printjson);

// 4.5 Ordenacao e limite: 3 melhores avaliados
print("--- 4.5 READ: top 3 por avaliacao ---");
db.livros.find({}, { titulo: 1, avaliacao: 1, _id: 0 }).sort({ avaliacao: -1 }).limit(3).forEach(printjson);

// ---------------------------------------------------------------------
// 5. UPDATE - atualizacoes
// ---------------------------------------------------------------------

// 5.1 updateOne com $set: emprestar "1984" nao, ele ja esta indisponivel;
//     aqui devolvemos o exemplar ao acervo.
print("--- 5.1 UPDATE: 1984 volta a estar disponivel ---");
printjson(
  db.livros.updateOne(
    { titulo: "1984" },
    { $set: { disponivel: true, avaliacao: 5.0 } }
  )
);

// 5.2 $push: adiciona categoria a um array existente
print("--- 5.2 UPDATE: nova categoria em Clean Code ---");
printjson(
  db.livros.updateOne(
    { titulo: "Clean Code" },
    { $push: { categorias: "Boas Praticas" } }
  )
);

// 5.3 $inc: corrige a contagem de paginas
print("--- 5.3 UPDATE: incrementa paginas de Dom Casmurro ---");
printjson(
  db.livros.updateOne(
    { titulo: "Dom Casmurro" },
    { $inc: { paginas: 16 } }
  )
);

// 5.4 updateMany: marca como indisponiveis os livros com nota baixa
print("--- 5.4 UPDATE: many, avaliacao menor que 4.5 ---");
printjson(
  db.livros.updateMany(
    { avaliacao: { $lt: 4.5 } },
    { $set: { disponivel: false } }
  )
);

print("--- Estado do acervo apos os UPDATEs ---");
db.livros.find({}, { titulo: 1, paginas: 1, disponivel: 1, avaliacao: 1, _id: 0 }).forEach(printjson);

// ---------------------------------------------------------------------
// 6. DELETE - remocao
// ---------------------------------------------------------------------

// 6.1 deleteOne: remove um livro especifico
print("--- 6.1 DELETE: remove O Cortico ---");
printjson(db.livros.deleteOne({ titulo: "O Cortico" }));

print("--- Total apos o DELETE ---");
printjson(db.livros.countDocuments());

// ---------------------------------------------------------------------
// 7. EXTRA - agregacao: quantidade de livros por categoria
// ---------------------------------------------------------------------
print("--- 7. AGREGACAO: livros por categoria ---");
db.livros.aggregate([
  { $unwind: "$categorias" },
  { $group: { _id: "$categorias", total: { $sum: 1 } } },
  { $sort: { total: -1, _id: 1 } }
]).forEach(printjson);

// ---------------------------------------------------------------------
// 8. DOCUMENTOS EMBUTIDOS: resenhas e emprestimos vivem dentro do livro.
// Uma leitura traz o livro completo, sem JOIN; cada escrita e atomica
// por ser feita num unico documento.
// ---------------------------------------------------------------------
print("--- 8. EMBUTIDOS: resenha + emprestimo ---");
db.livros.updateOne(
  { titulo: "Dom Casmurro" },
  { $push: { resenhas: { leitor: "Ana", nota: 5, texto: "Capitu tem olhos de ressaca.", created_at: new Date() } } }
);
// Emprestar = registrar o emprestimo E marcar indisponivel no mesmo update.
db.livros.updateOne(
  { titulo: "Dom Casmurro", disponivel: true },
  { $push: { emprestimos: { leitor: "Bruno", retirado_em: new Date() } }, $set: { disponivel: false } }
);
printjson(db.livros.findOne({ titulo: "Dom Casmurro" }, { titulo: 1, disponivel: 1, resenhas: 1, emprestimos: 1 }));

// ---------------------------------------------------------------------
// 9. INDICES + EXPLAIN: mesma consulta antes e depois do indice.
// COLLSCAN = varre a colecao inteira; IXSCAN = usa o indice.
// ---------------------------------------------------------------------
print("--- 9. EXPLAIN antes do indice ---");
const plano = (q) => db.livros.find(q).explain("executionStats");
const resumo = (e) => ({
  estagio: JSON.stringify(e.queryPlanner.winningPlan).match(/COLLSCAN|IXSCAN/)[0],
  docsExaminados: e.executionStats.totalDocsExamined,
  retornados: e.executionStats.nReturned
});
printjson(resumo(plano({ categorias: "Fantasia" })));

db.livros.createIndex({ categorias: 1 }); // multikey: uma entrada por item do array
db.livros.createIndex(
  { titulo: "text", autor: "text", categorias: "text" },
  { name: "busca_texto", default_language: "portuguese" }
);
print("--- 9. EXPLAIN depois do indice ---");
printjson(resumo(plano({ categorias: "Fantasia" })));

print("--- 9. BUSCA TEXTUAL com ranking por relevancia ---");
db.livros.find(
  { $text: { $search: "machado romance" } },
  { titulo: 1, score: { $meta: "textScore" } }
).sort({ score: { $meta: "textScore" } }).forEach(printjson);

// ---------------------------------------------------------------------
// 10. $facet: varios relatorios numa unica agregacao (usado no /painel do Rails)
// ---------------------------------------------------------------------
print("--- 10. $facet ---");
printjson(db.livros.aggregate([
  { $facet: {
    resumo: [{ $group: { _id: null, total: { $sum: 1 }, media: { $avg: "$avaliacao" },
                         disponiveis: { $sum: { $cond: ["$disponivel", 1, 0] } } } }],
    por_decada: [{ $match: { ano: { $type: "number" } } },
                 { $group: { _id: { $multiply: [{ $floor: { $divide: ["$ano", 10] } }, 10] }, total: { $sum: 1 } } },
                 { $sort: { _id: 1 } }],
    resenhas: [{ $unwind: "$resenhas" },
               { $group: { _id: "$titulo", media: { $avg: "$resenhas.nota" }, qtd: { $sum: 1 } } }]
  } }
]).toArray()[0]);

print("--- Fim do script ---");
