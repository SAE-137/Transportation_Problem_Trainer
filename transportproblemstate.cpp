#include "transportProblemState.h"

bool TransportProblemState::setData(const QVector<QVector<int>>& costMatrix,
                                    const QVector<int>& supply,
                                    const QVector<int>& demand,
                                    QString& errorText)
{
    errorText.clear();

    if (costMatrix.isEmpty() || costMatrix[0].isEmpty()) {
        errorText = "Матрица тарифов пуста.";
        return false;
    }

    const int rowsCount = costMatrix.size();
    const int colsCount = costMatrix[0].size();

    for (const auto& row : costMatrix) {
        if (row.size() != colsCount) {
            errorText = "Матрица тарифов имеет строки разной длины.";
            return false;
        }
    }

    if (supply.size() != rowsCount) {
        errorText = "Количество запасов не совпадает с числом строк.";
        return false;
    }

    if (demand.size() != colsCount) {
        errorText = "Количество потребностей не совпадает с числом столбцов.";
        return false;
    }

    m_rows = rowsCount;
    m_cols = colsCount;
    m_costMatrix = costMatrix;
    m_supply = supply;
    m_demand = demand;

    return true;
}

int TransportProblemState::rows() const
{
    return m_rows;
}

int TransportProblemState::cols() const
{
    return m_cols;
}

const QVector<QVector<int>>& TransportProblemState::costMatrix() const
{
    return m_costMatrix;
}

const QVector<int>& TransportProblemState::supply() const
{
    return m_supply;
}

const QVector<int>& TransportProblemState::demand() const
{
    return m_demand;
}

void TransportProblemState::clear()
{
    m_rows = 0;
    m_cols = 0;
    m_costMatrix.clear();
    m_supply.clear();
    m_demand.clear();
}
