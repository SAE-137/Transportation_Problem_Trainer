#ifndef TRANSPORTPROBLEMSTATE_H
#define TRANSPORTPROBLEMSTATE_H

#pragma once

#include <QVector>
#include <QString>

class TransportProblemState
{
public:
    bool setData(const QVector<QVector<int>>& costMatrix,
                 const QVector<int>& supply,
                 const QVector<int>& demand,
                 QString& errorText);

    int rows() const;
    int cols() const;

    const QVector<QVector<int>>& costMatrix() const;
    const QVector<int>& supply() const;
    const QVector<int>& demand() const;

    void clear();

private:
    int m_rows = 0;
    int m_cols = 0;

    QVector<QVector<int>> m_costMatrix;
    QVector<int> m_supply;
    QVector<int> m_demand;
};

#endif // TRANSPORTPROBLEMSTATE_H
