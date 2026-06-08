#ifndef POTENTIALSOLVER_H
#define POTENTIALSOLVER_H

#pragma once

#include <QString>
#include <QVector>

#include "transportproblemstate.h"

struct PotentialStep
{
    QString title;
    QString description;
    QString calculationText;

    QVector<QVector<int>> costMatrix;
    QVector<int> supply;
    QVector<int> demand;

    QVector<QVector<QString>> loadMatrix;
    QVector<QVector<QString>> markMatrix;

    int selectedRow = -1;
    int selectedCol = -1;
};

struct PotentialResult
{
    bool valid = false;
    bool optimal = false;
    QString message;

    int enterRow = -1;
    int enterCol = -1;

    QVector<PotentialStep> steps;
};

class PotentialSolver
{
public:
    PotentialResult solve(const TransportProblemState& source,
                          const QVector<QVector<QString>>& loadMatrix) const;

private:
    QVector<QVector<QString>> makeStringMatrix(int rows, int cols) const;
};

#endif // POTENTIALSOLVER_H
