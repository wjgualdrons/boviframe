# BOVIFrame

Aplicaci?n Flutter para gestionar sesiones y evaluaciones EPMURAS de productores ganaderos.

## Persistencia local y aislamiento por usuario

La identidad se mantiene en Firebase Auth para registro e inicio de sesi?n, pero los datos de la aplicaci?n se almacenan exclusivamente en Hive mediante `LocalFirestore`. Cada usuario autenticado recibe una caja independiente con el nombre `local_db_<uid>`; por tanto, sesiones, productores, evaluaciones, animales, noticias y perfiles no se comparten entre usuarios ni se env?an a Firestore/Realtime Database.

La capa local conserva la API de consultas que usaban las pantallas (`collection`, `doc`, `where`, `orderBy`, `get`, `snapshots`, `set`, `update`, `delete`) para que el cambio de almacenamiento no altere la navegaci?n. El acceso sin usuario autenticado falla expl?citamente en lugar de usar un usuario com?n.

## Mapa visual de pantallas

El diagrama completo est? en [`docs/pantallas.mmd`](docs/pantallas.mmd) y se puede abrir en cualquier visor Mermaid.

```mermaid
flowchart TD
  Splash[Splash] --> Login[Login]
  Login --> Register[Registro]
  Login --> Forgot[Recuperar contrase?a]
  Login --> Main[Men? principal]
  Main --> Dashboard[Dashboard / estad?sticas]
  Main --> Consulta[Consulta]
  Main --> Epmuras[EPMURAS]
  Main --> Settings[Ajustes]
  Main --> Theory[?ndice / bases te?ricas]
  Consulta --> Farm[Consulta de fincas]
  Consulta --> Animals[Consulta de animales]
  Farm --> Sessions[Sesiones de una finca]
  Sessions --> Detail[Detalle de animal]
  Epmuras --> NewSession[Nueva sesi?n]
  Epmuras --> EditSelector[Seleccionar sesi?n a editar]
  NewSession --> Producer[Datos del productor]
  NewSession --> Evaluation[Evaluaci?n animal]
  Producer --> Evaluation
  Evaluation --> Summary[Resumen de sesi?n]
  Evaluation --> Detail
  EditSelector --> EditSession[Editar sesi?n]
  EditSession --> EditProducer[Editar productor]
  EditSession --> Evaluation
  Main --> NewsPublic[Noticias p?blicas]
  NewsPublic --> NewsDetail[Detalle de noticia]
  NewsAdmin[Administrar noticias] --> NewsCreate[Crear noticia]
  NewsAdmin --> NewsEdit[Editar noticia]
  Settings --> EditFarm[Editar finca]
  Evaluation --> Pdf[Reporte / exportaci?n PDF]

  subgraph LocalDB[Hive local por uid]
    Profiles[(usuarios)]
    Sessions[(sesiones)]
    Producers[(datos_productor)]
    Evaluations[(evaluaciones_animales)]
    Animals[(animals)]
    News[(news)]
  end
  Login -. uid .-> LocalDB
  Producer -.-> Producers
  Evaluation -.-> Evaluations
  NewSession -.-> Sessions
  Consulta -.-> LocalDB
