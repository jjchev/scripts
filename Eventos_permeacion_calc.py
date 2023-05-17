import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
import tempfile
import subprocess
import shutil
import os
import json

print("Primer Peroxido: 3400. nc offset: 2")


def update_columns(file_path, firstAOX):
    # Cargamos el archivo CSV en un dataframe de Pandas
    event_df = pd.read_csv(file_path, index_col=0)

    # Actualizar las columnas a los datos de la trayectoria
    # Mas adelante agregar opcion de modificar offset y timestep
    event_df['Atom'] = event_df['Atom'] - 12 + firstAOX
    event_df['Start'] = event_df['Start'] * 2  # NetCDF stripeado cada 2 frames
    event_df['End'] = event_df['End'] * 2
    event_df['Duration'] = (
        (event_df['End'] -
         event_df['Start']) *
        0.02).round(2)  # 0.02 conversion de frame a ns
    return event_df


def get_duration_stats(df):
    # Agrupamos el dataframe por cadena
    chain_groups = df.groupby('Chain')

    # Calculamos la media y el desvío estándar de la columna Duration para
    # cada grupo
    duration_means = chain_groups['Duration'].mean().round(2)
    duration_stds = chain_groups['Duration'].std().round(2)
    event_counts = chain_groups.size()
    # Creamos un diccionario con los resultados
    duration_stats = {}
    for chain, mean, std, counts in zip(
            duration_means.index, duration_means, duration_stds, event_counts):
        duration_stats[chain] = {
            'event_count': counts,
            'mean_duration': mean,
            'duration_std': std}
    return duration_stats


def create_base_cpp(offset=1, topo='*.parm7'):
    # archivo base de CPPTRAJ para usar con las otras funciones
    with tempfile.NamedTemporaryFile(suffix=".cpp", delete=False) as cpp_base:
        # Cabecera de cargado de topologia y trayectoria
        cpp_base.write("parm {topo}\n".format(topo=topo).encode())
        cpp_base.write(
            "trajin Trayectoria/[0-9]00ns.nc 1 last {offset}\n".format(offset=offset).encode())
        cpp_base.write(
            "trajin Trayectoria/1000ns.nc 1 last {offset}\n".format(offset=offset).encode())
        cpp_base.write(b"autoimage\n")
        # Final, antes de esto van insertados los comandos
        cpp_base.write(b"go\n")
        cpp_base.write(b"exit\n")
        cpp_base.flush()
    return cpp_base.name


def insert_text_before_go(filename, text):
    temp_copy_filename = tempfile.mktemp()
    shutil.copyfile(filename, temp_copy_filename)

    output_filename = tempfile.mktemp()

    with open(output_filename, 'w') as file, open(temp_copy_filename, 'r') as temp_copy_file:
        lines = temp_copy_file.readlines()
        for line in lines:
            if line.strip() == 'go':
                with open(text, 'r') as temp_file:
                    file.write(temp_file.read() + '\n')
            file.write(line)

    os.remove(temp_copy_filename)

    return output_filename


def cpptraj_ArR_Center_Dihedral(residuos_cadenas):
    with tempfile.NamedTemporaryFile(suffix=".cpp", delete=False) as cpp_file:
        cadenas = ["A", "B", "C", "D"]
        for i, cadena in enumerate(cadenas):
            residuos = residuos_cadenas.split(',')[i * 4:(i + 1) * 4]
            # extrae el centro geometrico del ArR de cada cadena
            comando = "vector center :{} out {}_ArR.dat\n".format(
                ','.join(residuos), cadena)
            cpp_file.write(comando.encode())

        # Agrupar eventos por átomo y agregar comandos de centro y dihedro en
        # archivo temporal
        eventos = pd.read_csv("Eventos.csv")
        eventos_por_atomo = eventos.groupby("Atom")
        for atom, eventos_atom in eventos_por_atomo:
            comando = "vector center :{} out {}_center.dat\n".format(
                atom, atom)
            cpp_file.write(comando.encode())
            comando = "dihedral :{}@H1 :{}@O1 :{}@O2 :{}@H2 out {}_dihe.dat\n".format(
                atom, atom, atom, atom, atom)
            cpp_file.write(comando.encode())
            cpp_file.flush()
        return cpp_file.name


def run_cpptraj(cpp_file_name, backup):
    shutil.copy(cpp_file_name, backup)
    mpirun_args = [
        "mpirun",
        "-np",
        "8",
        "--use-hwthread-cpus",
        "cpptraj.MPI",
        "-i",
        cpp_file_name]
    subprocess.run(mpirun_args, check=True)


def cargar_archivos_arR(path='.'):
    # Cargamos los archivos ArR y los guardamos en un diccionario
    ar_files = {}
    for chain in ["A", "B", "C", "D"]:
        ar_filename = f"{chain}_ArR.dat"
        ar_path = os.path.join(path, ar_filename)
        ar_data = pd.read_csv(ar_path, delim_whitespace=True, skiprows=1, header=None,
                              names=["frame", "x", "y", "z", "a", "b", "c"])
        ar_files[chain] = ar_data
    return ar_files

def plotear_grafico_filtrado(final_data, atom):
    # Ploteamos z vs dihedro
    sns.scatterplot(x="z", y="Dihedro", data=final_data)
    plt.title(f"{atom}: Z vs Dihedro")
    plt.xlim(-15, 5)
    plt.savefig(f"{atom}_Z_vs_Dihe.png")
    plt.clf()  # Limpiamos la figura para el siguiente plot


def crear_archivos_filtrados(ar_files, path='.', plot=False):
    # Cargamos el archivo Eventos.csv
    eventos = pd.read_csv("Eventos.csv")

    for _, evento in eventos.iterrows():
        atom = evento["Atom"]
        chain = evento["Chain"]
        center_filename = f"{atom}_center.dat"
        dihe_filename = f"{atom}_dihe.dat"

        # Cargamos el archivo center y le restamos las columnas x, y y z del ArR correspondiente
        center_path = os.path.join(path, center_filename)
        center_data = pd.read_csv(center_path, delim_whitespace=True, skiprows=1, header=None,
                                  names=["frame", "x", "y", "z", "a", "b", "c"])
        ar_data = ar_files[chain]
        center_data[["x", "y", "z"]] -= ar_data[["x", "y", "z"]].values

        # Cargamos el archivo dihe y le agregamos la columna del dihedro
        dihe_path = os.path.join(path, dihe_filename)
        dihe_data = pd.read_csv(dihe_path, delim_whitespace=True, skiprows=1, header=None,
                                names=["frame", "Dihedro"])

        # Concatenamos center y dihe
        final_data = pd.concat([center_data[["frame", "x", "y", "z"]], dihe_data[["Dihedro"]]], axis=1)
        final_data = final_data.round(2)

        # Filtramos los valores de z que cumplan la condición ((x^2) + (y^2)) < 36
        final_data = final_data[(final_data["x"] ** 2 + final_data["y"] ** 2) < 36]

        # Guardamos el archivo filtrado
        final_data.to_csv(f"{atom}_filtered.dat", sep="\t", index=False, header=False)

        # Plotear gráfico si es necesario
        if plot:
            plotear_grafico_filtrado(final_data, atom)

        # Devolvemos el DataFrame filtrado
        yield final_data



##########################################################################


# cargar dataframe de eventos de permeacion creado por script de gera y formatearlos
# a resid y frames originales.
if __name__ == "__main__":
    # Bloque seteo inputs, aca cambia segun modelo, seteados para MtPIP2;3 w/3K AOX

    firstaox = 3400
    residuos_cadenas = "87,216,225,231,372,501,510,516,657,786,795,801,942,1071,1080,1086"

    data = update_columns('event_df.csv', firstaox)
    data.to_csv('Eventos.csv', index=False)
    print(get_duration_stats(data))
    with open('duration_stats.txt', 'w') as file:
        file.write(json.dumps(get_duration_stats(data), indent=4))

    base = create_base_cpp(offset=100, topo='*.parm7')
    input_arR_dihe_center = cpptraj_ArR_Center_Dihedral(residuos_cadenas)

    input_eventos = insert_text_before_go(base, input_arR_dihe_center)

    proceso = run_cpptraj(input_eventos, "./debug_input.cpp")

    resultados = crear_archivos_filtrados(cargar_archivos_arR(path='.'), path='.', plot=True)
    for resultado in resultados:
        print(resultado)
