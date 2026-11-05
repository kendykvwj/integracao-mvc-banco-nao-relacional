"""
Trabalho: Banco de dados NoSQL (MongoDB Atlas) - Acervo de Livros
CRUD completo com Python + pymongo.

Uso:
    python3 crud_livros.py

A string de conexao e lida da variavel de ambiente MONGODB_URI
(arquivo .env na mesma pasta). Nenhuma credencial fica no codigo.
"""

import os
import sys
from pathlib import Path

from pymongo import MongoClient
from pymongo.errors import ConnectionFailure, ConfigurationError

DB_NAME = "biblioteca"
COLLECTION_NAME = "livros"

LIVROS = [
    {
        "titulo": "Dom Casmurro",
        "autor": "Machado de Assis",
        "ano": 1899,
        "categorias": ["Romance", "Literatura Brasileira", "Classico"],
        "editora": "Livraria Garnier",
        "paginas": 256,
        "disponivel": True,
        "avaliacao": 4.7,
    },
    {
        "titulo": "O Cortico",
        "autor": "Aluisio Azevedo",
        "ano": 1890,
        "categorias": ["Naturalismo", "Literatura Brasileira"],
        "editora": "Editora Martin Claret",
        "paginas": 304,
        "disponivel": True,
        "avaliacao": 4.3,
    },
    {
        "titulo": "1984",
        "autor": "George Orwell",
        "ano": 1949,
        "categorias": ["Ficcao Cientifica", "Distopia", "Politica"],
        "editora": "Companhia das Letras",
        "paginas": 416,
        "disponivel": False,
        "avaliacao": 4.9,
    },
    {
        "titulo": "O Senhor dos Aneis: A Sociedade do Anel",
        "autor": "J. R. R. Tolkien",
        "ano": 1954,
        "categorias": ["Fantasia", "Aventura"],
        "editora": "HarperCollins",
        "paginas": 576,
        "disponivel": True,
        "avaliacao": 4.8,
    },
    {
        "titulo": "Clean Code",
        "autor": "Robert C. Martin",
        "ano": 2008,
        "categorias": ["Tecnologia", "Engenharia de Software"],
        "editora": "Prentice Hall",
        "paginas": 464,
        "disponivel": False,
        "avaliacao": 4.6,
    },
]


def carregar_env(caminho=".env"):
    """Le pares CHAVE=VALOR de um arquivo .env para os.environ."""
    arquivo = Path(__file__).parent / caminho
    if not arquivo.exists():
        return
    for linha in arquivo.read_text(encoding="utf-8").splitlines():
        linha = linha.strip()
        if not linha or linha.startswith("#") or "=" not in linha:
            continue
        chave, valor = linha.split("=", 1)
        os.environ.setdefault(chave.strip(), valor.strip().strip("\"'"))


def titulo(texto):
    print(f"\n{'=' * 70}\n{texto}\n{'=' * 70}")


def mostrar(documentos):
    for doc in documentos:
        doc.pop("_id", None)
        print(f"  {doc}")


def main():
    carregar_env()
    uri = os.environ.get("MONGODB_URI")
    if not uri:
        sys.exit("ERRO: defina MONGODB_URI no arquivo .env (veja .env.example).")

    try:
        client = MongoClient(uri, serverSelectionTimeoutMS=10000)
        client.admin.command("ping")
    except (ConnectionFailure, ConfigurationError) as erro:
        sys.exit(
            f"ERRO ao conectar no Atlas: {erro}\n"
            "Verifique: usuario em Database Access, IP em Network Access, "
            "e a senha na URI (caracteres especiais precisam de URL-encode)."
        )

    print("Conexao com o MongoDB Atlas estabelecida.")

    # 1. Banco e 2. colecao: criados no primeiro insert.
    db = client[DB_NAME]
    livros = db[COLLECTION_NAME]

    titulo("1 e 2. BANCO 'biblioteca' E COLECAO 'livros'")
    livros.drop()  # deixa o script reexecutavel sem duplicar dados
    db.create_collection(COLLECTION_NAME)
    livros = db[COLLECTION_NAME]
    print(f"  Colecoes no banco: {db.list_collection_names()}")

    # ---------------- CREATE ----------------
    titulo("3. CREATE - insercao dos 5 livros")
    resultado = livros.insert_many(LIVROS)
    print(f"  Documentos inseridos: {len(resultado.inserted_ids)}")
    print(f"  Total na colecao: {livros.count_documents({})}")

    # ---------------- READ ----------------
    titulo("4.1 READ - todos os livros")
    mostrar(livros.find())

    titulo("4.2 READ - somente os disponiveis")
    mostrar(livros.find({"disponivel": True}, {"titulo": 1, "autor": 1, "_id": 0}))

    titulo("4.3 READ - publicados a partir de 1950")
    mostrar(livros.find({"ano": {"$gte": 1950}}, {"titulo": 1, "ano": 1, "_id": 0}))

    titulo("4.4 READ - busca dentro do array categorias: 'Fantasia'")
    mostrar(livros.find({"categorias": "Fantasia"}, {"titulo": 1, "categorias": 1, "_id": 0}))

    titulo("4.5 READ - top 3 por avaliacao")
    mostrar(livros.find({}, {"titulo": 1, "avaliacao": 1, "_id": 0})
                  .sort("avaliacao", -1).limit(3))

    # ---------------- UPDATE ----------------
    titulo("5.1 UPDATE - $set: 1984 volta ao acervo com nota 5.0")
    r = livros.update_one({"titulo": "1984"},
                          {"$set": {"disponivel": True, "avaliacao": 5.0}})
    print(f"  encontrados={r.matched_count} modificados={r.modified_count}")

    titulo("5.2 UPDATE - $push: nova categoria em Clean Code")
    r = livros.update_one({"titulo": "Clean Code"},
                          {"$push": {"categorias": "Boas Praticas"}})
    print(f"  encontrados={r.matched_count} modificados={r.modified_count}")

    titulo("5.3 UPDATE - $inc: +16 paginas em Dom Casmurro")
    r = livros.update_one({"titulo": "Dom Casmurro"}, {"$inc": {"paginas": 16}})
    print(f"  encontrados={r.matched_count} modificados={r.modified_count}")

    titulo("5.4 UPDATE - update_many: avaliacao < 4.5 fica indisponivel")
    r = livros.update_many({"avaliacao": {"$lt": 4.5}},
                           {"$set": {"disponivel": False}})
    print(f"  encontrados={r.matched_count} modificados={r.modified_count}")

    titulo("Estado do acervo apos os UPDATEs")
    mostrar(livros.find({}, {"titulo": 1, "paginas": 1, "disponivel": 1,
                             "avaliacao": 1, "_id": 0}))

    # ---------------- DELETE ----------------
    titulo("6. DELETE - remove 'O Cortico'")
    r = livros.delete_one({"titulo": "O Cortico"})
    print(f"  removidos={r.deleted_count}")
    print(f"  Total na colecao: {livros.count_documents({})}")

    # ---------------- AGREGACAO ----------------
    titulo("7. AGREGACAO - quantidade de livros por categoria")
    pipeline = [
        {"$unwind": "$categorias"},
        {"$group": {"_id": "$categorias", "total": {"$sum": 1}}},
        {"$sort": {"total": -1, "_id": 1}},
    ]
    for doc in livros.aggregate(pipeline):
        print(f"  {doc['_id']}: {doc['total']}")

    client.close()
    print("\nFim da execucao.")


if __name__ == "__main__":
    main()
